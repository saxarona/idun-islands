using CSV
using DataFrames
using IdunIslands
using MPI
using OrderedCollections
using Statistics

# We need MPI.Init()

MPI.Init()

comm = MPI.COMM_WORLD
ranks = MPI.Comm_size(comm)
myrank = MPI.Comm_rank(comm)

dest = mod(rank+1, size)
src = mod(rank-1, size)

function islandGA(
    logbook::Logbook,
    f::Function,
    pop::AbstractVector,
    max_it::Integer,
    S_P::SelectionMethod,
    X::CrossoverMethod,
    Mut::MutationMethod,
    μ::Integer,
    S_M::DemeSelector,
    R_M::DemeReplacer,
)
    n = length(pop)
    comm_stats = []
	for i in 1:max_it  # main loop
		parents = select(S_P, f.(pop)) # O(max_it * n)
		offspring = [cross(X, pop[p[1]], pop[p[2]]) for p in parents]
		pop .= mutate.(Ref(Mut), offspring) # whole population is replaced

        fitnesses = f.(pop) # O(max_it * n)

        if i % μ == 0  # migration time
            # Migration
            # 1. Select deme
            chosen = IdunIslands.select(S_M, fitnesses)
            # 2. Send demehttps://www.youtube.com/watch?list=RDMMSAsJAR2MoPs&v=lej5QC3RaaU
            # TODO: who is dest?
            _, s_req = IdunIslands.drift!(pop, chosen, dest; comm=MPI.COMM_WORLD)
            # 3. Receive deme
            # TODO: who is src?
            M, r_req = IdunIslands.strand!(pop, S_M.k, src; comm=MPI.COMM_WORLD)
            # 4. Reinsert deme
            IdunIslands.reinsert!(pop, fitnesses, R_M, M; rng=GLOBAL_RNG)
            # 5. Evaluate deme
            push!(fitnesses, f.(M))
            push!(comm_stats, MPI.WaitAll([r_req, s_req]))
        end
        # Save stats
        compute!(logbook, fitnesses)
	end

    # x, fx
	best, best_i = findmin(f, pop) # O(n)
	n_evals = 2 * max_it * n + n
    result = Result(best, pop[best_i], pop, max_it, n_evals)
	return result, comm_stats  # of this island!
end

# 1. Init
## GA operators
d = 10  # dimensions
f(x) = michalewicz(x)  # objective function
lb = zeros(d)  # lower bound
ub = fill(π, d)  # upper bound
n = 30  # population size
P = unif_rand_vector_pop(n, lb, ub)  # population
S_P = TournamentSelectionGenerational(5)  # parent selection policy
X = UniformCrossover()  # crossover method
Mut = GaussianMutation()  # mutation method
max_it = 100

## Island operators
k = 0.1*n  # deme size
S_M = RandomDemeSelector(k)  # migration selection policy
R_M = WorstReplacer(0.3)  # migration replacement policy
μ = 10

# Extras
statnames = ["max", "min", "avg", "median"]
fns = [maximum, minimum, mean, median]
thedict = LittleDict(statnames, fns)
statsbook = Logbook(thedict)

# call to optimiser
i_res, i_stats = islandGA(statsbook, f, P, max_it, S_P, X, Mut, μ, S_M, R_M)

print("Comm stats for this island:\n $i_stats\n")

df = DataFrame(statsbook.records)
CSV.write("data_$myrank.csv", df)

print("That's it from island $myrank!\n")
