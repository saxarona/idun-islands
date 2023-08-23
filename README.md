# Islands on Idun

This is a project exploring how to implement island models of genetic algorithms using Message Passing Interface (MPI) on a high performance computing cluster.

The project is an extension of [EvoLP.jl](https://github.com/ntnu-ai-lab/EvoLP.jl) and provides 3 new additional operators.

## The work flow

### Select a deme

We have a new supertype: `DemeSelector` which uses `select` to choose a subset of a population (or _deme_, as it is known in biology).
This project implements the following hierarchy of deme selector types:

- `DemeSelector`
  - `RandomDemeSelector`
  - `WorstDemeSelector`

Both the random and worst deme selectors get a parameter `k` to select `k` individuals from the population using such policy.

### Drift away

After a `DemeSelector` has been chosen, it is passed to the new function `drift`.
The `drift` operator calls on the `select` function using the chosen `DemeSelector`.
It then encodes and sends the deme to the destination island.

### Strand in

The new function `strand` handles the receiving and decoding of the population.

### Reinsert

Another new function, `reinsert!`, takes the new stranded deme and adds it (in-place) to the population.
It then returns the indices of the old deme (which should be deleted manually from your algorithm).

## Implementation and results

We ported EvoLP to Julia 1.7.2 and renamed it IdunIslands.
For simplicity, all new components (as well as a demo algorithm, `islandGA`) were added to a single file: `island.jl`.
Members in this file are not exported, so everything needs to be accessed by `IdunIslands.WorstDemeSelector`, for  example.
The running script is `scratch.jl` which wraps everything in a single work flow run.

We tested on 8 cores (or 8 islands) using a 1-way ring topology.
Three built-in functions were tested: `ackley`, `rosenbrock` and `michalewicz`, each on three different dimension sizes: 2, 3 and 5.
More information about them is available at EvoLP's documentation on [benchmark functions](https://ntnu-ai-lab.github.io/EvoLP.jl/stable/man/benchmarks.html).

### Tests setup

A generational GA (`islandGA`) with:

- Generator: `unif_rand_vector_pop`
- Selector: `RankBasedSelectionGenerational`
- Recombinator: `UniformCrossover`
- Mutator: `GaussianMutation` with `std=0.1`
- Population size: 30
- Iterations: 100
- Migration
  - rate: `mu` (see below)
  - selection policy: `RandomDemeSelector`
  - replacement policy: `WorstDemeSelector`

| param  	| ackley 	| rosenbrock 	| michalewicz 	|
|--------	|--------	|------------	|-------------	|
| `mu`     	| 10     	| 10         	| 5           	|

Tested on Julia 1.7.2, using 2 nodes of 4 cores each on [Idun](https://www.hpc.ntnu.no/idun/).

Results are available in the data folder, per function, per dimension, per island.
These were logged using EvoLP's [statistics logbook](https://ntnu-ai-lab.github.io/EvoLP.jl/stable/man/logbook.html).
