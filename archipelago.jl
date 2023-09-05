using CSV
using EvoLP
using Islands
using MPI
using OrderedCollections
using Statistics
import DataFrames: DataFrame

const SAVE = true

function experiment(popsize, ParentSelector, Recombinator, Mutator, max_its,
            DemeSelector, Reinserter, stat_callables, stat_names,
            dimensions, obj_functions, p_bounds, m_rates;
    SAVE=true)
    for (exp_i, f) in enumerate(obj_functions)  # for each experiment/objective function
        fname = string(f)
        for d in dimensions  # for each dimension
            lb = fill(p_bounds[exp_i][1], d)  # lower bound
            ub = fill(p_bounds[exp_i][2], d)  # upper bound
            P = unif_rand_vector_pop(popsize, lb, ub)  # population

            μ = m_rates[exp_i]  # epoch

            # new logbook per experiment
            thedict = LittleDict(stat_names, stat_callables)
            statsbook = Logbook(thedict)

            # call to optimiser
            i_res, i_stats = islandGA(statsbook, f, P, max_its,
                ParentSelector, Recombinator, Mutator, p_bounds[exp_i],
                μ, DemeSelector, Reinserter, dest, src, comm
            )
            print("""Result on island $(myrank) for $(f) function with d=$(d):
                    $(optimum(i_res))
                    achieved by $(optimizer(i_res))\n""")
            df = DataFrame(statsbook.records)
            if SAVE
                CSV.write("./data/$(fname)/d$(d)/data_$(myrank).csv", df)
            end
        end
    end
    print("That's it from island $(myrank)!\n")
end

MPI.Init()

comm = MPI.COMM_WORLD
ranks = MPI.Comm_size(comm)
myrank = MPI.Comm_rank(comm)

dest = mod(myrank+1, ranks)
src = mod(myrank-1, ranks)

#0. Setup
# GA operators
n = 30  # population size
S_P = RankBasedSelectionGenerational()  # parent selection policy
X = UniformCrossover()  # crossover method
Mut = GaussianMutation(0.1)  # mutation method
max_it = 100  # max iterations of optimiser

# Island operators
k = 0.1*n  # deme size
S_M = RandomDemeSelector(k)  # migration selection policy
R_M = WorstDemeSelector(k)  # migration replacement policy

# Extras
statfs = [minimum, maximum, mean, median, std]
statnames = [string(x) for x in statfs]

# Exp 1: easy, medium, hard functions
# 1. Init
ds = [2, 5, 10]  # dimensions
fs = [ackley, rosenbrock, michalewicz]  # objective functions
bounds = [(-32.768, 32.768), (-2.048, 2.048), (0, π)]
mus = [10, 10, 5]  # migration rates

#2. run
experiment(n, S_P, X, Mut, max_it, S_M, R_M, statfs, statnames, ds, fs, bounds, mus; SAVE=SAVE)

# Exp 2: multimodals
ds = [2, 3, 5]  # dimensions
fs = [eggholder, rana]  # objective functions
bounds = [(-512, 512), (-512, 512)]
mus = [10, 10]  # migration rates

# 2. run
experiment(n, S_P, X, Mut, max_it, S_M, R_M, statfs, statnames, ds, fs, bounds, mus; SAVE=SAVE)
