#!/bin/bash
# Warm up the GPU and leave a benchmark figure behind.
#
# Runs entirely offline: the CUDA toolkit is already in the image, so this
# compiles and runs locally and finishes in a couple of minutes. Nothing is
# downloaded, so a slow link can't delay or defeat it.
#
# Everything here is yours to edit — this is just a starting point.
set -euo pipefail

echo "== GPU =="
nvidia-smi

# A small matrix-multiply benchmark, compiled on the box with the baked-in
# toolkit. cuBLAS is what real workloads spend their time in, so this is a
# more honest number than a synthetic loop.
cat > /tmp/bench.cu <<'CUDA'
#include <cstdio>
#include <cublas_v2.h>
#include <cuda_runtime.h>

int main() {
  const int n = 8192;                       // 8192^3 multiply-adds per pass
  const size_t bytes = (size_t)n * n * sizeof(float);
  float *a, *b, *c;
  // Unified memory: on GB10 the CPU and GPU share one physical pool, so this
  // is not the copy it would be on a discrete card.
  cudaMallocManaged(&a, bytes);
  cudaMallocManaged(&b, bytes);
  cudaMallocManaged(&c, bytes);
  for (size_t i = 0; i < (size_t)n * n; i++) { a[i] = 1.0f; b[i] = 2.0f; }

  cublasHandle_t h; cublasCreate(&h);
  const float alpha = 1.0f, beta = 0.0f;
  // One untimed pass first: the first call pays for context setup and
  // autotuning, which would otherwise land in the measurement.
  cublasSgemm(h, CUBLAS_OP_N, CUBLAS_OP_N, n, n, n, &alpha, a, n, b, n, &beta, c, n);
  cudaDeviceSynchronize();

  cudaEvent_t start, stop; cudaEventCreate(&start); cudaEventCreate(&stop);
  const int iters = 10;
  cudaEventRecord(start);
  for (int i = 0; i < iters; i++)
    cublasSgemm(h, CUBLAS_OP_N, CUBLAS_OP_N, n, n, n, &alpha, a, n, b, n, &beta, c, n);
  cudaEventRecord(stop); cudaEventSynchronize(stop);

  float ms = 0.0f; cudaEventElapsedTime(&ms, start, stop);
  double flop = 2.0 * n * n * (double)n * iters;   // 2 ops per multiply-add
  printf("FP32 dense matmul: %.1f TFLOP/s (n=%d)\n", flop / (ms / 1000.0) / 1e12, n);
  cublasDestroy(h);
  return 0;
}
CUDA

nvcc -O3 -o /tmp/bench /tmp/bench.cu -lcublas
/tmp/bench

echo
echo "GPU is up and working. Nothing is left running — the box is yours."
