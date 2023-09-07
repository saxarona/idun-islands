# Evolutionary Computation with Islands: Extending EvoLP.jl for Parallel Computing

Companion code for the paper at the 35th Norwegian ICT Conference for Research and Education.
This paper presents an extension of [EvoLP.jl](https://github.com/ntnu-ai-lab/EvoLP.jl) and provides 3 new additional operators that can be used to set up island models of genetic algorithms in parallel machines.

## Run the model

Clone, activate and instantiate the environment as you would with any other Julia env.
Then, submit `archipelago.jl` to the cluster. For example, using SLURM, it would be something like this:

```bash
#SBATCH -J test-job
#SBATCH --account=my-hpc-account
#SBATCH --ntasks-per-node=32        # 32 islands
#SBATCH -c 1                        # single threaded island
#SBATCH -t 00:05:00                 # estimated time
#SBATCH -p CPUQ                     # HPC partition
#SBATCH --output=out/test_%j.out    # output dump

module load foss/2022a
module load Julia/1.7.2-linux-x86_64

srun julia archipelago.jl
```

## Code structure

The wrapper script for a parallel run is `archipelago.jl`.
Its single core equivalent is `singlecore.jl`.

Generated data for parallel runs can be found in the `data` directory.
Single core data is in the `singlecore` directory.

Utilities for data handling and plotting can be found in the `analysis` directory.

All core additions to EvoLP.jl are in the `src/island.jl` file. The components are:

### Deme selection blocks

- `DemeSelector`
  - `RandomDemeSelector`
  - `WorstDemeSelector`
- `select` method for deme selection

### Communication blocks

- `drift`
- `strand`
- `reinsert!`

### Miscellaneous components

- **Mutator**: `mutate` method. Patched version of `EvoLP.mutate` but checking problem bounds (see [EvoLP's issue #69](https://github.com/ntnu-ai-lab/EvoLP.jl/issues/69))
- **Test function**: `eggholder`
- **Test function**: `rana`
- **Algorithm**: `islandGA`

## Using the communication blocks

### Select a deme

We have a new supertype: `DemeSelector`, used by the  `select` method to choose a subset of a population (or _deme_).

Both the random and worst deme selectors can get a parameter `k` to select `k` individuals from the population using such policy.

### Drift away

After a `DemeSelector` has been chosen, it is passed to the new function `drift`.
The `drift` operator calls on the `select` function using the chosen `DemeSelector`.
It then encodes and sends the deme to the destination island.

### Strand in

The new function `strand` handles the receiving and decoding of the population.

### Reinsert!

Another new function, `reinsert!`, takes the new stranded deme and adds it (in-place) to the population.
It then returns the indices of the old deme (which should be deleted manually from your algorithm).

## Implementation and results

All parallel tests were carried out using Julia 1.7.2 on Idun, [NTNU’s HPC solution](https://www.hpc.ntnu.no/idun/).

We tested on 64 cores (or 64 islands) using a 1-way ring topology.
Five built-in functions were tested:

- From EvoLP.jl: `ackley`, `rosenbrock` and `michalewicz` (Test 1)
- Available in `island.jl`: `eggholder` and `rana` (Test 2)

### Tests setup

A generational GA (`islandGA`) with:

- Generator: `EvoLP.unif_rand_vector_pop`
- Selector: `EvoLP.RankBasedSelectionGenerational`
- Recombinator: `EvoLP.UniformCrossover`
- Mutator: `EvoLP.GaussianMutation` with `std=0.1`
- Population size `popsize`: 30
- Iterations: 100
- Migration
  - rate: `mu` (see below)
  - selection policy: `RandomDemeSelector` with `k=0.1*popsize`
  - replacement policy: `WorstDemeSelector` with `k=0.1*popsize`

| param  	| ackley 	| rosenbrock 	| michalewicz 	| eggholder | rana   |
|--------	|--------	|------------	|-------------	|-----------|--------|
| `mu`   	| 10   	  | 10          | 5             |10         |10      |

Results are available in the data folder, per function, per dimension, per island.
These were logged using EvoLP's [statistics logbook](https://ntnu-ai-lab.github.io/EvoLP.jl/stable/man/logbook.html).
