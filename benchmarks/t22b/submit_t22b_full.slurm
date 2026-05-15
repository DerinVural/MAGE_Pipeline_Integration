#!/bin/bash
#SBATCH -A proj68
#SBATCH -p kolyoz-cuda
#SBATCH --qos=normal
#SBATCH -J t22b_full
#SBATCH -N 1
#SBATCH --ntasks-per-node=1
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=16
#SBATCH --time=23:59:00
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err

set -uo pipefail

echo "=========================================="
echo "JOB:    $SLURM_JOB_ID  ($SLURM_JOB_NAME)"
echo "NODE:   $(hostname)"
echo "GPUS:   $CUDA_VISIBLE_DEVICES"
echo "START:  $(date -Is)"
echo "=========================================="

# --- Environment ---
source /etc/profile.d/modules.sh
module purge
module load apps/truba-ai/gpu-2024.0
WS=/arf/scratch/merdal/mage_bench
source $WS/venv/bin/activate
export PATH=$WS/iverilog_env/bin:$PATH
export PYTHONPATH=$WS/repo/src:${PYTHONPATH:-}

# Offline HF (model already downloaded)
export HF_HOME=$WS/hf_cache
export TRANSFORMERS_OFFLINE=1
export HF_HUB_OFFLINE=1

# vLLM cache / temp dirs to scratch
export VLLM_CACHE_ROOT=$WS/.vllm_cache
mkdir -p $VLLM_CACHE_ROOT
export TMPDIR=$WS/.tmp
mkdir -p $TMPDIR

echo "--- iverilog ---"
which iverilog
iverilog -V | head -2
echo "--- python ---"
which python
python -c "import vllm; print('vllm', vllm.__version__)"
python -c "import torch; print('torch', torch.__version__, 'cuda', torch.version.cuda)"

# --- Run dir ---
RUN_DIR=$WS/runs/t22b_full
mkdir -p $RUN_DIR
cd $RUN_DIR

# Bring in the repo's verilog-eval submodule + tests parent
ln -snf $WS/repo/verilog-eval verilog-eval
cp -f $WS/repo/tests/test_top_agent.py .
cp -f $WS/repo/tests/test_top_agent_gemma4_e4b_bf16_full.py ./reference_runner.py 2>/dev/null || true
cp -f $WS/test_t22b_gemma4_26b_full.py .

MODEL_PATH=$WS/models/gemma-4-26B-A4B-it
VLLM_PORT=8000

# --- vLLM server (background) ---
echo "=== Starting vLLM server ==="
nohup vllm serve $MODEL_PATH \
  --served-model-name google/gemma-4-26B-A4B-it \
  --port $VLLM_PORT \
  --dtype bfloat16 \
  --max-model-len 32768 \
  --enforce-eager \
  --enable-prefix-caching \
  > vllm_serve.log 2>&1 &
VLLM_PID=$!
echo "vLLM PID: $VLLM_PID"

# --- Wait for ready ---
echo "=== Waiting for vLLM ready (timeout 10 min) ==="
for i in $(seq 1 120); do
  if curl -fsS http://localhost:$VLLM_PORT/v1/models > /dev/null 2>&1; then
    echo "vLLM ready after $((i*5))s"
    break
  fi
  if ! kill -0 $VLLM_PID 2>/dev/null; then
    echo "ERROR: vLLM process died before ready"
    tail -50 vllm_serve.log
    exit 1
  fi
  sleep 5
done

curl -s http://localhost:$VLLM_PORT/v1/models | python3 -m json.tool

# --- Run smoke test ---
echo "=== Running smoke ==="
export VLLM_BASE_URL=http://localhost:$VLLM_PORT/v1
python test_t22b_gemma4_26b_full.py
EXIT_CODE=$?

# --- Cleanup ---
echo "=== Cleanup ==="
kill $VLLM_PID 2>/dev/null
wait $VLLM_PID 2>/dev/null

echo "=== END $(date -Is) ==="
echo "Exit code: $EXIT_CODE"
exit $EXIT_CODE
