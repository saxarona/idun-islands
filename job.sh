#!/usr/bin/bash
#SBATCH -J julia-mpi-test
#SBATCH --account=share-ie-idi
#SBATCH -N 1                        # 2 nodes for the job
#SBATCH --ntasks-per-node=1         # Single task
#SBATCH -c 2                        # 1 core on each node
#SBATCH -t 00:10:00                 # time
#SBATCH -p CPUQ                     # partition
#SBATCH --output=out/test_%j.out    # output dump

module load foss/2022a
module load Julia/1.7.2-linux-x86_64

WORKDIR=${SLURM_SUBMIT_DIR}

cd ${WORKDIR}
# srun julia archipelago.jl
srun julia scratch.jl
