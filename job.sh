#!/usr/bin/bash
#SBATCH -J julia-mpi-test
#SBATCH --account=share-ie-idi
#SBATCH -N 2                        # 2 nodes for the job
#SBATCH --ntasks-per-node=4         # 4 cores per node
#SBATCH -c 1                        # single threaded
#SBATCH -t 00:10:00                 # max time
#SBATCH -p CPUQ                     # partition
#SBATCH --output=out/test_%j.out    # output dump

module load foss/2022a
module load Julia/1.7.2-linux-x86_64

WORKDIR=${SLURM_SUBMIT_DIR}

cd ${WORKDIR}
# srun julia archipelago.jl
srun julia scratch.jl
