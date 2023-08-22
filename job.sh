#!/usr/bin/bash
#SBATCH -J julia-mpi-test
#SBATCH --account=share-ie-idi
#SBATCH --mail-user=xavier.sanchezdz@ntnu.no
#SBATCH -N 1                        # 1 node for the job
#SBATCH --ntasks-per-node=32        # 16 tasks per cpu
#SBATCH -c 1                        # single threaded
#SBATCH -t 00:15:00                 # time
#SBATCH -p CPUQ                     # partition
#SBATCH --output=out/test_%j.out    # output dump
#SBATCH --mem=16000
#SBATCH --mail-type=ALL

module load foss/2022a
module load Julia/1.7.2-linux-x86_64

WORKDIR=${SLURM_SUBMIT_DIR}

cd ${WORKDIR}
# srun julia archipelago.jl
srun julia archipelago.jl
