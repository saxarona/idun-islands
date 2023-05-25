using CSV
using IdunIslands
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
## GA operators
d = 10  # dimensions
f(x) = michalewicz(x)  # objective function
lb = zeros(d)  # lower bound
ub = fill(π, d)  # upper bound
n = 30  # population size
P = unif_rand_vector_pop(n, lb, ub)  # population
S_P = RankBasedSelection()  # parent selection policy
X = UniformCrossover()  # crossover method
Mut = GaussianMutation(0.5)  # mutation method
max_it = 100  # max iterations of optimiser

## Island operators
k = 0.1*n  # deme size
S_M = IdunIslands.RandomDemeSelector(k)  # migration selection policy
R_M = Idun.Islands.WorstDemeSelector(k)  # migration replacement policy
μ = 10

# Extras
statnames = ["max", "min", "avg", "median"]
fns = [maximum, minimum, mean, median]
thedict = LittleDict(statnames, fns)
statsbook = Logbook(thedict)

# call to optimiser
i_res, i_stats = IdunIslands.islandGA(statsbook, f, P, max_it, S_P, X, Mut, μ, S_M, R_M)

print("Comm stats for this island:\n $i_stats\n")
print("Result on island $(myrank): $(optimum(i_res)) achieved by $(optimizer(i_res))\n")
df = DataFrame(statsbook.records)
CSV.write("./data/data_$(myrank).csv", df)

print("That's it from island $(myrank)!\n")
