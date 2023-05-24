# Island model extensions

# Deme selectors return indices!

abstract type DemeSelector end

struct RandomDemeSelector <: DemeSelector
    k
end

struct WorstDemeSelector <: DemeSelector
    k
end


"""
    select(S_M::RandomDemeSelector, y; rng=GLOBAL_RNG)

Returns a random subset of `S_M.k` indices from the population.
"""
function select(S_M::RandomDemeSelector, y; rng=GLOBAL_RNG)
    return sample(1:length(y), S_M.k, replace=false)
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
    M = splice!(population, chosen)
    #MPI SEND TO DESTINATION
    s_req = MPI.Isend(M, comm; dest=dest)  # Should I use tag?
    return M, s_req
end

"""
    strand!(population, k, src; comm=MPI.COMM_WORLD)

Adds received deme into the population. Returns the received request of MPI.
"""
function strand!(population, k, src; comm=MPI.COMM_WORLD)
    #MPI RECEIVE FROM SOURCE
    M = similar(population, k)
    r_req = MPI.Irecv!(M, comm; source=src)  # Should I use tag?
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
    reinsert!(population, y, R::WorstReplacer, M; rng=GLOBAL_RNG)

Insert deme `M` into `population` by replacing the worst individuals, with a probability
`R.p` of success.
"""
function reinsert!(population, y, R::WorstReplacer, M; rng=GLOBAL_RNG)
    #find worst
    k = length(M)
    worst = partialsortperm(y, k; rev=true)
    for i in 1:k
        if rand() < R.p
            deleteat!(population, worst[i])
            deleteat!(y, worst[i])
            push!(population, M[i])
        end
    end
    return
end
