#!/bin/bash
echo "Cpu only" 
./Panorama cpu 500 images
echo "" 
echo "Naive Global Kernel" 
./Panorama global 500 images
echo "" 
echo "Naive Register Kernel" 
./Panorama register 500 images
echo "" 
echo "Optimized Shared Kernel" 
./Panorama shared 500 images
echo "" 
echo "CUBLAS Matrix Multiplication" 
./Panorama cublas 500 images
echo "" 
echo "Opencv Builtin Kernel" 
./Panorama cvgpu 500 images
echo "" 
echo "Cpu Multiplication CUDA Warping" 
./Panorama cpu 500 images --cudawarp
echo "" 
echo "Cpu Multiplication CUDA Convolution" 
./Panorama cpu 500 images --cudaconvolve