using MPI
using EvoLP

# We need MPI.Init()

MPI.Init()

comm = MPI.COMM_WORLD
ranks = MPI.Comm_size(comm)
myrank = MPI.Comm_rank(comm)

print("Hello world from rank $(myrank) of $(ranks)\n")

# 1. Init
d = 10  # dimensions
lb = zeros(d)  # lower bound
ub = fill(π, d)  # upper bound
P = unif_rand_vector_pop(n, lb, ub)  # Population
S_P = TournamentSelectionGenerational(5)  # Parent selection policy
C = UniformCrossover()  # Crossover method
M = GaussianMutation()  # Mutation method

# 2. Select deme
