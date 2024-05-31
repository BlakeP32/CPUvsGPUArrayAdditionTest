//
//  compute.metal
//  gpushizz
//
//  Created by Blake Peery on 5/31/24.
//

#include <metal_stdlib>
using namespace metal;


kernel void additon_compute_func(constant float *arr1 [[ buffer(0) ]],
                                 constant float *arr2 [[ buffer(1) ]],
                                 device float *resultArr [[ buffer(2) ]],
                                 uint index [[ thread_position_in_grid ]]){
    resultArr[index] = arr1[index] + arr2[index];
}


