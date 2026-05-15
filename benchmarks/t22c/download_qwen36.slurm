#!/bin/bash
#SBATCH -A proj68
#SBATCH -p kolyoz-cuda
#SBATCH -J dl_qwen36
#SBATCH -N 1
#SBATCH --ntasks-per-node=1
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=16
#SBATCH --time=02:00:00
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err

source /etc/profile.d/modules.sh
module load apps/truba-ai/gpu-2024.0
source /arf/scratch/merdal/mage_bench/venv/bin/activate
export HF_HOME=/arf/scratch/merdal/mage_bench/hf_cache

cd /arf/scratch/merdal/mage_bench
hf download Qwen/Qwen3.6-27B --local-dir /arf/scratch/merdal/mage_bench/models/Qwen3.6-27B
echo "DONE $(date)"
