// RUN: mlir-opt %s -canonicalize -split-input-file | FileCheck %s

// CHECK-LABEL: func @memref_cast(
func @memref_cast(%a: index, %b: index) -> memref<?x?xf32> {
  %c0 = constant 0 : index
  %c1 = constant 1 : index
  %c8 = constant 8 : index
  %c16 = constant 16 : index
  %1 = alloc (%b) : memref<?xi8>
  %2 = view %1[%c0][] : memref<?xi8> to memref<16x16xf32>
  %3 = memref_cast %2 : memref<16x16xf32> to memref<?x?xf32>
  %r0 = linalg.range %c0:%c8:%c1 : !linalg.range

  // CHECK:  linalg.slice {{.*}} : memref<16x16xf32>, !linalg.range, !linalg.range, memref<?x?xf32>
  %4 = linalg.slice %3[%r0, %r0] : memref<?x?xf32>, !linalg.range, !linalg.range, memref<?x?xf32>

  // CHECK:  linalg.matmul ins({{.*}}memref<16x16xf32>, memref<16x16xf32>) outs({{.*}}memref<16x16xf32>)
  linalg.matmul ins(%3, %3: memref<?x?xf32>, memref<?x?xf32>)
               outs(%3: memref<?x?xf32>)
  return %4: memref<?x?xf32>
}

// -----

func @collapsing_tensor_reshapes(%arg0 : tensor<?x?x?x?x?xf32>) -> tensor<?x?xf32>
{
  %0 = linalg.tensor_reshape %arg0
         [affine_map<(d0, d1, d2, d3, d4) -> (d0, d1)>,
          affine_map<(d0, d1, d2, d3, d4) -> (d2)>,
          affine_map<(d0, d1, d2, d3, d4) -> (d3, d4)>] :
       tensor<?x?x?x?x?xf32> into tensor<?x?x?xf32>
  %1 = linalg.tensor_reshape %0
         [affine_map<(d0, d1, d2) -> (d0, d1)>,
          affine_map<(d0, d1, d2) -> (d2)>] :
       tensor<?x?x?xf32> into tensor<?x?xf32>
  return %1 : tensor<?x?xf32>
}
//   CHECK-DAG: #[[$MAP0:.*]] = affine_map<(d0, d1, d2, d3, d4) -> (d0, d1, d2)>
//   CHECK-DAG: #[[$MAP1:.*]] = affine_map<(d0, d1, d2, d3, d4) -> (d3, d4)>
// CHECK-LABEL: collapsing_tensor_reshapes
//       CHECK:   linalg.tensor_reshape %{{.*}} [#[[$MAP0]], #[[$MAP1]]]
//   CHECK-NOT:   linalg.tensor_reshape

// -----

// -----

func @collapsing_tensor_reshapes_to_zero_dim(%arg0 : tensor<1x1x1xf32>)
                                             -> tensor<f32> {
  %0 = linalg.tensor_reshape %arg0 [affine_map<(d0, d1, d2) -> (d0, d1, d2)>] :
       tensor<1x1x1xf32> into tensor<1xf32>
  %1 = linalg.tensor_reshape %0 [] : tensor<1xf32> into tensor<f32>
  return %1 : tensor<f32>
}
// CHECK-LABEL: collapsing_tensor_reshapes_to_zero
//       CHECK:   linalg.tensor_reshape %{{.*}} []
//  CHECK-SAME:     tensor<1x1x1xf32> into tensor<f32>

// -----

func @collapsing_memref_reshapes_to_zero_dim(%arg0 : memref<1x1x1xf32>)
                                             -> memref<f32> {
  %0 = linalg.reshape %arg0 [affine_map<(d0, d1, d2) -> (d0, d1, d2)>] :
       memref<1x1x1xf32> into memref<1xf32>
  %1 = linalg.reshape %0 [] : memref<1xf32> into memref<f32>
  return %1 : memref<f32>
}
// CHECK-LABEL: collapsing_memref_reshapes_to_zero
//       CHECK:   linalg.reshape %{{.*}} []
//  CHECK-SAME:     memref<1x1x1xf32> into memref<f32>

// -----

func @expanding_tensor_reshapes(%arg0 : tensor<?x?xf32>) -> tensor<?x?x?x?x?xf32>
{
  %0 = linalg.tensor_reshape %arg0
         [affine_map<(d0, d1, d2) -> (d0, d1)>,
          affine_map<(d0, d1, d2) -> (d2)>] :
       tensor<?x?xf32> into tensor<?x?x?xf32>
  %1 = linalg.tensor_reshape %0
         [affine_map<(d0, d1, d2, d3, d4) -> (d0, d1)>,
          affine_map<(d0, d1, d2, d3, d4) -> (d2)>,
          affine_map<(d0, d1, d2, d3, d4) -> (d3, d4)>] :
       tensor<?x?x?xf32> into tensor<?x?x?x?x?xf32>
  return %1 : tensor<?x?x?x?x?xf32>
}
//   CHECK-DAG: #[[$MAP0:.*]] = affine_map<(d0, d1, d2, d3, d4) -> (d0, d1, d2)>
//   CHECK-DAG: #[[$MAP1:.*]] = affine_map<(d0, d1, d2, d3, d4) -> (d3, d4)>
// CHECK-LABEL: expanding_tensor_reshapes
//       CHECK:   linalg.tensor_reshape %{{.*}} [#[[$MAP0]], #[[$MAP1]]]
//   CHECK-NOT:   linalg.tensor_reshape

// -----

func @collapsing_memref_reshapes(%arg0 : memref<?x?x?x?x?xf32>) -> memref<?x?xf32>
{
  %0 = linalg.reshape %arg0
         [affine_map<(d0, d1, d2, d3, d4) -> (d0, d1)>,
          affine_map<(d0, d1, d2, d3, d4) -> (d2)>,
          affine_map<(d0, d1, d2, d3, d4) -> (d3, d4)>] :
       memref<?x?x?x?x?xf32> into memref<?x?x?xf32>
  %1 = linalg.reshape %0
         [affine_map<(d0, d1, d2) -> (d0, d1)>,
          affine_map<(d0, d1, d2) -> (d2)>] :
       memref<?x?x?xf32> into memref<?x?xf32>
  return %1 : memref<?x?xf32>
}
//   CHECK-DAG: #[[$MAP0:.*]] = affine_map<(d0, d1, d2, d3, d4) -> (d0, d1, d2)>
//   CHECK-DAG: #[[$MAP1:.*]] = affine_map<(d0, d1, d2, d3, d4) -> (d3, d4)>
// CHECK-LABEL: collapsing_memref_reshapes
//       CHECK:   linalg.reshape %{{.*}} [#[[$MAP0]], #[[$MAP1]]]
//   CHECK-NOT:   linalg.reshape

// -----

func @expanding_memref_reshapes(%arg0 : memref<?x?xf32>) -> memref<?x?x?x?x?xf32>
{
  %0 = linalg.reshape %arg0
         [affine_map<(d0, d1, d2) -> (d0, d1)>,
          affine_map<(d0, d1, d2) -> (d2)>] :
       memref<?x?xf32> into memref<?x?x?xf32>
  %1 = linalg.reshape %0
         [affine_map<(d0, d1, d2, d3, d4) -> (d0, d1)>,
          affine_map<(d0, d1, d2, d3, d4) -> (d2)>,
          affine_map<(d0, d1, d2, d3, d4) -> (d3, d4)>] :
       memref<?x?x?xf32> into memref<?x?x?x?x?xf32>
  return %1 : memref<?x?x?x?x?xf32>
}
//   CHECK-DAG: #[[$MAP0:.*]] = affine_map<(d0, d1, d2, d3, d4) -> (d0, d1, d2)>
//   CHECK-DAG: #[[$MAP1:.*]] = affine_map<(d0, d1, d2, d3, d4) -> (d3, d4)>
// CHECK-LABEL: expanding_memref_reshapes
//       CHECK:   linalg.reshape %{{.*}} [#[[$MAP0]], #[[$MAP1]]]
//   CHECK-NOT:   linalg.reshape

// -----

func @expanding_tensor_reshapes_to_zero_dim(%arg0 : tensor<f32>)
                                             -> tensor<1x1x1xf32> {
  %0 = linalg.tensor_reshape %arg0 [] : tensor<f32> into tensor<1xf32>
  %1 = linalg.tensor_reshape %0 [affine_map<(d0, d1, d2) -> (d0, d1, d2)>] :
       tensor<1xf32> into tensor<1x1x1xf32>
  return %1 : tensor<1x1x1xf32>
}
// CHECK-LABEL: expanding_tensor_reshapes_to_zero
//       CHECK:   linalg.tensor_reshape %{{.*}} []
//  CHECK-SAME:     tensor<f32> into tensor<1x1x1xf32>

// -----

func @expanding_memref_reshapes_to_zero_dim(%arg0 : memref<f32>)
                                             -> memref<1x1x1xf32> {
  %0 = linalg.reshape %arg0 [] : memref<f32> into memref<1xf32>
  %1 = linalg.reshape %0
         [affine_map<(d0, d1, d2) -> (d0, d1, d2)>] :
       memref<1xf32> into memref<1x1x1xf32>
  return %1 : memref<1x1x1xf32>
}
// CHECK-LABEL: expanding_memref_reshapes_to_zero
//       CHECK:   linalg.reshape %{{.*}} []
//  CHECK-SAME:     memref<f32> into memref<1x1x1xf32>

// -----

func @fold_tensor_reshape(%arg0 : tensor<12x4xf32>) -> tensor<12x4xf32>
{
  %0 = linalg.tensor_reshape %arg0
         [affine_map<(d0, d1, d2) -> (d0, d1)>,
          affine_map<(d0, d1, d2) -> (d2)>] :
       tensor<12x4xf32> into tensor<3x4x4xf32>
  %1 = linalg.tensor_reshape %0
         [affine_map<(d0, d1, d2) -> (d0, d1)>,
          affine_map<(d0, d1, d2) -> (d2)>] :
       tensor<3x4x4xf32> into tensor<12x4xf32>
  return %1 : tensor<12x4xf32>
}
// CHECK-LABEL: @fold_tensor_reshape
//   CHECK-NOT:   linalg.tensor_reshape

// -----

func @no_fold_tensor_reshape(%arg0 : tensor<?x?xf32>) -> tensor<?x?xf32>
{
  %0 = linalg.tensor_reshape %arg0
         [affine_map<(d0, d1, d2) -> (d0, d1)>,
          affine_map<(d0, d1, d2) -> (d2)>] :
       tensor<?x?xf32> into tensor<?x?x?xf32>
  %1 = linalg.tensor_reshape %0
         [affine_map<(d0, d1, d2) -> (d0, d1)>,
          affine_map<(d0, d1, d2) -> (d2)>] :
       tensor<?x?x?xf32> into tensor<?x?xf32>
  return %1 : tensor<?x?xf32>
}
// CHECK-LABEL: @no_fold_tensor_reshape
//       CHECK:   linalg.tensor_reshape
//       CHECK:   linalg.tensor_reshape

// -----

func @fold_memref_reshape(%arg0 : memref<12x4xf32>) -> memref<12x4xf32>
{
  %0 = linalg.reshape %arg0
         [affine_map<(d0, d1, d2) -> (d0, d1)>,
          affine_map<(d0, d1, d2) -> (d2)>] :
       memref<12x4xf32> into memref<3x4x4xf32>
  %1 = linalg.reshape %0
         [affine_map<(d0, d1, d2) -> (d0, d1)>,
          affine_map<(d0, d1, d2) -> (d2)>] :
       memref<3x4x4xf32> into memref<12x4xf32>
  return %1 : memref<12x4xf32>
}
// CHECK-LABEL: @fold_memref_reshape
//   CHECK-NOT:   linalg.reshape

// -----

func @no_fold_memref_reshape(%arg0 : memref<?x?xf32>) -> memref<?x?xf32>
{
  %0 = linalg.reshape %arg0
         [affine_map<(d0, d1, d2) -> (d0, d1)>,
          affine_map<(d0, d1, d2) -> (d2)>] :
       memref<?x?xf32> into memref<?x?x?xf32>
  %1 = linalg.reshape %0
         [affine_map<(d0, d1, d2) -> (d0, d1)>,
          affine_map<(d0, d1, d2) -> (d2)>] :
       memref<?x?x?xf32> into memref<?x?xf32>
  return %1 : memref<?x?xf32>
}
// CHECK-LABEL: @no_fold_memref_reshape
//       CHECK:   linalg.reshape
//       CHECK:   linalg.reshape

// -----

#accesses = [
  affine_map<(i) -> (i)>,
  affine_map<(i) -> (i)>
]

#trait = {
  indexing_maps = #accesses,
  iterator_types = ["parallel"]
}

func @dce_zero_memref(%arg0 : memref<0xf32>, %arg1: tensor<0xf32>) -> tensor<0xf32> {
  // memref<0x32> is expected to be dce'ed
  linalg.copy(%arg0, %arg0): memref<0xf32>, memref<0xf32>

  // tensor<0xf32> cannot be dce'ed
  %1 = linalg.generic #trait ins(%arg1 : tensor<0xf32>) {
  ^bb(%0: f32) :
    linalg.yield %0 : f32
  } -> tensor<0xf32>

  return %1: tensor<0xf32>
}
// CHECK-LABEL: @dce_zero_memref
//   CHECK-NOT:   linalg.copy
//  CHECK-NEXT:   linalg.generic

// -----

func @reshape_splat_constant_int32() -> tensor<2x4x2xi32>
{
  %c0 = constant dense<42> : tensor<2x8xi32>
  %0 = linalg.tensor_reshape %c0
         [affine_map<(d0, d1, d2) -> (d0)>,
          affine_map<(d0, d1, d2) -> (d1, d2)>]
       : tensor<2x8xi32> into tensor<2x4x2xi32>
  return %0 : tensor<2x4x2xi32>
}
// CHECK-LABEL: @reshape_splat_constant_int32
//       CHECK:   %[[CST:.*]] = constant dense<{{.*}}> : tensor<2x4x2xi32>
//   CHECK-NOT:   linalg.tensor_reshape
//       CHECK:   return %[[CST]]

func @reshape_splat_constant_int16() -> tensor<2x4x2xi16>
{
  %c0 = constant dense<42> : tensor<2x8xi16>
  %0 = linalg.tensor_reshape %c0
         [affine_map<(d0, d1, d2) -> (d0)>,
          affine_map<(d0, d1, d2) -> (d1, d2)>]
       : tensor<2x8xi16> into tensor<2x4x2xi16>
  return %0 : tensor<2x4x2xi16>
}
// CHECK-LABEL: @reshape_splat_constant_int16
//       CHECK:   %[[CST:.*]] = constant dense<{{.*}}> : tensor<2x4x2xi16>
//   CHECK-NOT:   linalg.tensor_reshape
//       CHECK:   return %[[CST]]

func @reshape_splat_constant_float32() -> tensor<2x4x2xf32>
{
  %c0 = constant dense<42.0> : tensor<2x8xf32>
  %0 = linalg.tensor_reshape %c0
         [affine_map<(d0, d1, d2) -> (d0)>,
          affine_map<(d0, d1, d2) -> (d1, d2)>]
       : tensor<2x8xf32> into tensor<2x4x2xf32>
  return %0 : tensor<2x4x2xf32>
}
// CHECK-LABEL: @reshape_splat_constant_float32
//       CHECK:   %[[CST:.*]] = constant dense<{{.*}}> : tensor<2x4x2xf32>
//   CHECK-NOT:   linalg.tensor_reshape
//       CHECK:   return %[[CST]]

func @reshape_splat_constant_float64() -> tensor<2x4x2xf64>
{
  %c0 = constant dense<42.0> : tensor<2x8xf64>
  %0 = linalg.tensor_reshape %c0
         [affine_map<(d0, d1, d2) -> (d0)>,
          affine_map<(d0, d1, d2) -> (d1, d2)>]
       : tensor<2x8xf64> into tensor<2x4x2xf64>
  return %0 : tensor<2x4x2xf64>
}
// CHECK-LABEL: @reshape_splat_constant_float64
//       CHECK:   %[[CST:.*]] = constant dense<{{.*}}> : tensor<2x4x2xf64>
//   CHECK-NOT:   linalg.tensor_reshape
//       CHECK:   return %[[CST]]

// -----

// CHECK-LABEL: func @tensor_cast(
func @tensor_cast(%a : tensor<3x4xf32>, %b : tensor<4x?xf32>, %c : tensor<3x?xf32>)
  -> tensor<3x?xf32>
{
  %ta = tensor_cast %a : tensor<3x4xf32> to tensor<?x?xf32>
  %tb = tensor_cast %b : tensor<4x?xf32> to tensor<?x?xf32>
  %tc = tensor_cast %c : tensor<3x?xf32> to tensor<?x?xf32>

  //      CHECK:  linalg.matmul ins({{.*}}tensor<3x4xf32>, tensor<4x?xf32>)
  // CHECK-SAME:    init({{.*}}tensor<3x?xf32>) -> tensor<3x?xf32>
  %0 = linalg.matmul ins(%ta, %tb: tensor<?x?xf32>, tensor<?x?xf32>)
               init(%tc: tensor<?x?xf32>) -> tensor<?x?xf32>

  %1 = tensor_cast %0 : tensor<?x?xf32> to tensor<3x?xf32>

  return %1: tensor<3x?xf32>
}

// -----

// CHECK-LABEL: func @linalg_effects(
//  CHECK-SAME:     %[[A:[a-z0-9]*]]: tensor<?x?xf32>
//  CHECK-SAME:     %[[B:[a-z0-9]*]]: memref<?x?xf32>
//  CHECK-SAME:     %[[C:[a-z0-9]*]]: tensor<?x?xf32>
func @linalg_effects(%a : tensor<?x?xf32>, %b : memref<?x?xf32>, %c : tensor<?x?xf32>) {
  // CHECK-NOT:   %{{.*}} = linalg.matmul
  %t = linalg.matmul ins(%a, %b : tensor<?x?xf32>, memref<?x?xf32>)
                    init(%c : tensor<?x?xf32>) -> tensor<?x?xf32>

  // CHECK-NOT:   %{{.*}} = linalg.matmul
  linalg.matmul ins(%a, %c : tensor<?x?xf32>, tensor<?x?xf32>)
               outs(%b : memref<?x?xf32>)
  return
}
