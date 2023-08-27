# Island model extensions

# Deme selectors return indices!

abstract type DemeSelector end

struct RandomDemeSelector <: DemeSelector
    k::Integer
end

struct WorstDemeSelector <: DemeSelector
    k::Integer
end


"""
    select(S_M::RandomDemeSelector, y)

Returns a random subset of `S_M.k` indices from the population.
"""
function select(S_M::RandomDemeSelector, y)
    n = length(y)
    return sample(1:n, S_M.k, replace=false, ordered=true)
end

"""
    select(S_M::WorstDemeSelector, y)

Returns the indices of the S_M.`k`-worst individuals in the population.
"""

function select(S_M::WorstDemeSelector, y)
    worst = partialsortperm(y, 1:S_M.k; rev=true)
    return sort(worst)
end


# Communication blocks

"""
    drift(population, chosen, dest; comm=MPI.COMM_WORLD)

Removes chosen indices from the population and sends it to adjacent island.
Returns the send request of MPI.
"""
function drift(S_M::DemeSelector, population, y, dest; comm=MPI.COMM_WORLD)
    M = Vector{Vector{Float64}}(undef, S_M.k)
    #select here
    chosen = Islands.select(S_M, y)
    for i in eachindex(chosen)
        M[i] = population[chosen[i]]
    end
    encoded_M = reduce(vcat, M)
    #MPI SEND TO DESTINATION
    s_req = MPI.Send(encoded_M, comm; dest=dest)  # Should I use tag?
    return M, s_req
end

"""
    strand!(population, k, src; comm=MPI.COMM_WORLD)

Adds received deme into the population. Returns the received request of MPI.
"""
function strand(S_M::DemeSelector, d, src; comm=MPI.COMM_WORLD)
    #MPI RECEIVE FROM SOURCE
    encoded_M = Array{Float64}(undef, S_M.k * d)
    r_req = MPI.Recv!(encoded_M, comm; source=src)  # Should I use tag?
    M = []
    for i in 1:d:length(encoded_M)
        push!(M, encoded_M[i:i+d-1])
    end
    return M, r_req
end

"""
    reinsert!(population, y, R_M::DemeSelector, M)

Insert deme `M` into `population` and returns selected individuals' indices for removal.
Selection is performed using policy determined by `R_M`.
"""
function reinsert!(population, y, R_M::DemeSelector, M)
    replaced = Islands.select(R_M, y)  # get indices
    append!(population, M)
    return replaced
end


# Island GA

function islandGA(
    logbook::Logbook,
    f::Function,
    pop::AbstractVector,
    max_it::Integer,
    S_P::EvoLP.SelectionMethod,
    X::EvoLP.CrossoverMethod,
    Mut::EvoLP.MutationMethod,
    μ::Integer,
    S_M::Islands.DemeSelector,
    R_M::Islands.DemeSelector,
    dest::Integer,
    src::Integer,
    comm
)
    n = length(pop)
    d = length(pop[1])
    comm_stats = []
	for i in 1:max_it  # main loop
		parents = EvoLP.select(S_P, f.(pop)) # O(max_it * n)
		offspring = [cross(X, pop[p[1]], pop[p[2]]) for p in parents]
		pop .= mutate.(Ref(Mut), offspring) # whole population is replaced

        fitnesses = f.(pop) # O(max_it * n)

        if i % μ == 0  # migration time
            # Migration
            # 1. Select and send deme
            _, s_req = drift(S_M, pop, fitnesses, dest; comm=MPI.COMM_WORLD)
            # 3. Receive deme
            M, r_req = strand(S_M, d, src; comm=MPI.COMM_WORLD)
            # WAIT
            # MPI.Barrier(comm)
            # 4. Add new deme
            worst = reinsert!(pop, fitnesses, R_M, M)
            # 5. Delete old deme
            deleteat!(pop, worst)
            deleteat!(fitnesses, worst)
            # 5. Evaluate new deme
            append!(fitnesses, f.(M))  # O(max_it / μ * S_M.k)
            # push!(comm_stats, MPI.Waitall([r_req, s_req]))
            MPI.Barrier(comm)
        end
        compute!(logbook, fitnesses)  # Save stats
	end

    # x, fx
	best, best_i = findmin(f, pop) # O(n)  #  this is not efficient, I know
	n_evals = 2 * max_it * n + n
    result = Result(best, pop[best_i], pop, max_it, n_evals)
	return result, comm_stats  # of this island!
end
