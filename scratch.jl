using MPI

# We need MPI.Init()

MPI.Init()

comm = MPI.COMM_WORLD
ranks = MPI.Comm_size(comm)
myrank = MPI.Comm_rank(comm)

print("Hello world from rank $(myrank) of $(ranks)\n")
