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
Returns a random subset of the population of size `k`.
"""
function select(::RandomDemeSelector, y, k; rng=GLOBAL_RNG)
    return sample(1:length(y), k, replace=false)
end

"""
Returns the indices of the `k`-worst individuals in the population.
"""

function select(::WorstDemeSelector, y, k; rng=GLOBAL_RNG)
    worst = partialsortperm(y, k; rev=true)
    return worst
end


function drift!(population, indices, destination)
    M = splice!(population, indices)
    #MPI SEND TO DESTINATION
end

# Deme replacers:

abstract type DemeReplacer end

struct WorstReplacer <: DemeReplacer
    p
end

function reinsert!(population, y, R::WorstReplacer, M)
    #find worst
    k = length(M)
    worst = partialsortperm(y, k; rev=true)
    for i in 1:k
        if rand() < R.p
            deleteat!(population, worst[i])
            push!(population, M[i])
        end
    end
end
