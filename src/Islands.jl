module Islands

import StatsBase: sample

using EvoLP
using MPI
using CSV


# Deme Selection
export RandomDemeSelector, WorstDemeSelector
export select

# Island operators
export drift, strand, reinsert!
export islandGA

# Benchmarks
export eggholder

include("island.jl")

end
