// RUN: xla-cpu-opt %s -split-input-file -empty-tensor-to-alloc-tensor \
// RUN:   -one-shot-bufferize | FileCheck %s

func.func @max_reduce(%arg0: tensor<10xf32>) -> tensor<10xf32> {
  %0 = tensor.empty() : tensor<10xf32>
  %1 = "xla_cpu.all_reduce"(%arg0, %0) {
    channel_handle = 5 : i64,
    reduction_kind = 3 : i32,
    replica_groups = dense<[]> : tensor<0xi64>,
    use_global_device_ids = 0 : i32
  } : (tensor<10xf32>, tensor<10xf32>) -> tensor<10xf32>
  return %1 : tensor<10xf32>
}

// CHECK-LABEL: @max_reduce
//  CHECK-SAME:   %[[ARG0:.*]]: tensor<10xf32>
//       CHECK: %[[ARG0_MEMREF:.*]] = bufferization.to_memref %[[ARG0]]
//       CHECK: %[[OUT:.*]] = memref.alloc() {{.*}} memref<10xf32>
//       CHECK: "xla_cpu.all_reduce"(%[[ARG0_MEMREF]], %[[OUT]]) {
//  CHECK-SAME:   channel_handle = 5
//       CHECK: %[[RESULT:.*]] = bufferization.to_tensor %[[OUT]]
//       CHECK: return %[[RESULT]]

// -----

func.func @collective_permute(%arg0: tensor<16x8xf32>) -> tensor<16x8xf32> {
  %0 = tensor.empty() : tensor<16x8xf32>
  %1 = "xla_cpu.collective_permute"(%arg0, %0) {
    channel_handle = 1 : i64,
    source_target_pairs = dense<[[0, 1], [1, 2], [2, 3]]> : tensor<3x2xi64>
  } : (tensor<16x8xf32>, tensor<16x8xf32>) -> tensor<16x8xf32>
  return %1 : tensor<16x8xf32>
}

// CHECK-LABEL: @collective_permute
//  CHECK-SAME:   %[[ARG0:.*]]: tensor<16x8xf32>
//       CHECK: %[[ARG0_MEMREF:.*]] = bufferization.to_memref %[[ARG0]]
//       CHECK: %[[OUT:.*]] = memref.alloc() {{.*}} memref<16x8xf32>
//       CHECK: "xla_cpu.collective_permute"(%[[ARG0_MEMREF]], %[[OUT]]) {
//  CHECK-SAME:   channel_handle = 1
//       CHECK: %[[RESULT:.*]] = bufferization.to_tensor %[[OUT]]
//       CHECK: return %[[RESULT]]

// -----

func.func @all_to_all(%arg0: tensor<4x16xf32>) -> tensor<16x4xf32> {
  %0 = tensor.empty() : tensor<16x4xf32>
  %1 = "xla_cpu.all_to_all"(%arg0, %0) {
    concat_dimension = 0 : i64,
    replica_groups = dense<[[0, 1, 2, 3]]> : tensor<1x4xi64>,
    split_count = 4 : i64,
    split_dimension = 1 : i64
  } : (tensor<4x16xf32>, tensor<16x4xf32>) -> tensor<16x4xf32>
  return %1 : tensor<16x4xf32>
}

// CHECK-LABEL: @all_to_all
//  CHECK-SAME:   %[[ARG0:.*]]: tensor<4x16xf32>
//       CHECK: %[[ARG0_MEMREF:.*]] = bufferization.to_memref %[[ARG0]]
//       CHECK: %[[OUT:.*]] = memref.alloc() {{.*}} memref<16x4xf32>
//       CHECK: "xla_cpu.all_to_all"(%[[ARG0_MEMREF]], %[[OUT]]) {
//  CHECK-SAME:   split_count = 4
//       CHECK: %[[RESULT:.*]] = bufferization.to_tensor %[[OUT]]
//       CHECK: return %[[RESULT]]

func.func @fft(%arg0: tensor<3x5x4x8x256xf32>) -> tensor<3x5x4x8x129xcomplex<f32>> {
  %0 = tensor.empty() : tensor<3x5x4x8x129xcomplex<f32>>
  %1 = "xla_cpu.fft"(%arg0, %0) {
    fft_length = [4, 8, 256],
    fft_type = 2 : i32
   } : (tensor<3x5x4x8x256xf32>,tensor<3x5x4x8x129xcomplex<f32>>) -> tensor<3x5x4x8x129xcomplex<f32>>
  return %1 : tensor<3x5x4x8x129xcomplex<f32>>
}

// CHECK-LABEL: @fft
//  CHECK-SAME:   %[[ARG0:.*]]: tensor<3x5x4x8x256xf32>
//       CHECK: %[[ARG0_MEMREF:.*]] = bufferization.to_memref %[[ARG0]]
//       CHECK: %[[OUT:.*]] = memref.alloc() {{.*}}
//       CHECK: "xla_cpu.fft"(%[[ARG0_MEMREF]], %[[OUT]])
