module Islands

import StatsBase: sample

using EvoLP
using MPI
using CSV
using Random


# Deme Selection
export RandomDemeSelector, WorstDemeSelector
export select

# Island operators
export drift, strand, reinsert!
export islandGA
export mutate

# Benchmarks
export eggholder
export rana

include("island.jl")

end
