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
    worst = partialsortperm(y, S_M.k; rev=true)
    return worst
end


# Communication blocks

"""
    drift!(population, chosen, dest; comm=MPI.COMM_WORLD)

Removes chosen indices from the population and sends it to adjacent island.
Returns the send request of MPI.
"""
function drift!(population, chosen, dest; comm=MPI.COMM_WORLD)
    M = Vector{Vector{Float64}}(undef, length(chosen))
    for i in 1:length(chosen)
        M[i] = population[chosen[i]]
    end
    encoded_M = reduce(vcat, M)
    #MPI SEND TO DESTINATION
    s_req = MPI.Isend(encoded_M, comm; dest=dest)  # Should I use tag?
    return M, s_req
end

"""
    strand!(population, k, src; comm=MPI.COMM_WORLD)

Adds received deme into the population. Returns the received request of MPI.
"""
function strand!(population, k, d, src; comm=MPI.COMM_WORLD)
    #MPI RECEIVE FROM SOURCE
    encoded_M = Array{Float64}(undef, k * d)
    r_req = MPI.Irecv!(encoded_M, comm; source=src)  # Should I use tag?
    M = []
    for i in 1:d:length(encoded_M)
        push!(M, encoded_M[i:i+d-1])
    end
    return M, r_req
end


# Deme replacers:

abstract type DemeReplacer end

"""
Replaces worst individuals with an individual probability `p` of success.
"""
struct WorstReplacer <: DemeReplacer
    p
end

"""
    reinsert!(population, y, R::WorstReplacer, M)

Insert deme `M` into `population` by replacing the worst individuals
"""
function reinsert!(population, y, R::WorstReplacer, M)
    #find worst
    k = length(M)
    worst = partialsortperm(y, 1:k; rev=true)
    for i in 1:k
        push!(population, M[i])
    end
    return sort(worst)
end
