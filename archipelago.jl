using CSV
using EvoLP
using Islands
using MPI
using OrderedCollections
using Statistics
import DataFrames: DataFrame

MPI.Init()

comm = MPI.COMM_WORLD
ranks = MPI.Comm_size(comm)
myrank = MPI.Comm_rank(comm)

dest = mod(myrank+1, ranks)
src = mod(myrank-1, ranks)

# 1. Init
ds = [2, 3, 5]  # dimensions
fs = [ackley, rosenbrock, michalewicz]  # objective functions
bounds = [(-32.768, 32.768), (-2.048, 2.048), (0, π)]
mus = [5, 5, 10]  # migration rates

## GA operators
n = 30  # population size
S_P = RankBasedSelectionGenerational()  # parent selection policy
X = UniformCrossover()  # crossover method
Mut = GaussianMutation(0.1)  # mutation method
max_it = 100  # max iterations of optimiser

## Island operators
k = 0.1*n  # deme size
S_M = RandomDemeSelector(k)  # migration selection policy
R_M = WorstDemeSelector(k)  # migration replacement policy

# Extras
statnames = ["max", "min", "avg", "median"]
statfs = [maximum, minimum, mean, median]

for (exp_i, f) in enumerate(fs)  # for each experiment/objective function
    fname = string(f)
    for d in ds  # for each dimension
        lb = fill(bounds[exp_i][1], d)  # lower bound
        ub = fill(bounds[exp_i][2], d)  # upper bound
        P = unif_rand_vector_pop(n, lb, ub)  # population

        μ = mus[exp_i]  # epoch

        # new logbook per experiment
        thedict = LittleDict(statnames, statfs)
        statsbook = Logbook(thedict)

        # call to optimiser
        i_res, i_stats = islandGA(
            statsbook, f, P, max_it, S_P, X, Mut,
            μ, S_M, R_M, dest, src, comm
        )
        # print("Comm stats for this island:\n $i_stats\n")
        print("""Result on island $(myrank) for $(f) function with d=$(d):
                 $(optimum(i_res))
                 achieved by $(optimizer(i_res))\n""")
        df = DataFrame(statsbook.records)
        CSV.write("./data/$(fname)/d$(d)/data_$(myrank).csv", df)

        print("That's it from island $(myrank)!\n")
    end
end
