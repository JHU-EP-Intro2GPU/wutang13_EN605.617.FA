/*M///////////////////////////////////////////////////////////////////////////////////////
//
//  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.
//
//  By downloading, copying, installing or using the software you agree to this license.
//  If you do not agree to this license, do not download, install,
//  copy or use the software.
//
//
//                           License Agreement
//                For Open Source Computer Vision Library
//
// Copyright (C) 2000-2008, Intel Corporation, all rights reserved.
// Copyright (C) 2009, Willow Garage Inc., all rights reserved.
// Third party copyrights are property of their respective owners.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
//   * Redistribution's of source code must retain the above copyright notice,
//     this list of conditions and the following disclaimer.
//
//   * Redistribution's in binary form must reproduce the above copyright notice,
//     this list of conditions and the following disclaimer in the documentation
//     and/or other materials provided with the distribution.
//
//   * The name of the copyright holders may not be used to endorse or promote products
//     derived from this software without specific prior written permission.
//
// This software is provided by the copyright holders and contributors "as is" and
// any express or implied warranties, including, but not limited to, the implied
// warranties of merchantability and fitness for a particular purpose are disclaimed.
// In no event shall the Intel Corporation or contributors be liable for any direct,
// indirect, incidental, special, exemplary, or consequential damages
// (including, but not limited to, procurement of substitute goods or services;
// loss of use, data, or profits; or business interruption) however caused
// and on any theory of liability, whether in contract, strict liability,
// or tort (including negligence or otherwise) arising in any way out of
// the use of this software, even if advised of the possibility of such damage.
//
//M*/

#include "opencv2/opencv_modules.hpp"

#ifndef HAVE_OPENCV_CUDEV

#error "opencv_cudev is required"

#else

#include "opencv2/cudev.hpp"
// jwootan - added cublas
#include <cublas.h>
#include <stdio.h>
#define  BLOCK_SIZE 16
//---------------------------

using namespace cv::cudev;

void mulMat(const GpuMat& src1, const GpuMat& src2, GpuMat& dst, const GpuMat&, double scale, Stream& stream, int);
void mulMat_8uc4_32f(const GpuMat& src1, const GpuMat& src2, GpuMat& dst, Stream& stream);
void mulMat_16sc4_32f(const GpuMat& src1, const GpuMat& src2, GpuMat& dst, Stream& stream);
// jwootan - new kernels
void mulMatExperiment(float* src1, float* src2, float* dst, size_t arraySize, CUDA_MEM_TYPE memType);
void sgmmNaive(float* _src1, float* _src2, float* _dst, int rows, int cols);
//----------------------------------------

namespace
{
    template <typename T, typename D> struct MulOp : binary_function<T, T, D>
    {
        __device__ __forceinline__ D operator ()(T a, T b) const
        {
            return saturate_cast<D>(a * b);
        }
    };

    template <typename T, typename S, typename D> struct MulScaleOp : binary_function<T, T, D>
    {
        S scale;

        __device__ __forceinline__ D operator ()(T a, T b) const
        {
            return saturate_cast<D>(scale * a * b);
        }
    };

    template <typename ScalarDepth> struct TransformPolicy : DefaultTransformPolicy
    {
    };
    template <> struct TransformPolicy<double> : DefaultTransformPolicy
    {
        enum {
            shift = 1
        };
    };

    template <typename T, typename S, typename D>
    void mulMatImpl(const GpuMat& src1, const GpuMat& src2, const GpuMat& dst, double scale, Stream& stream)
    {
        if (scale == 1)
        {
            MulOp<T, D> op;
            gridTransformBinary_< TransformPolicy<S> >(globPtr<T>(src1), globPtr<T>(src2), globPtr<D>(dst), op, stream);
        }
        else
        {
            MulScaleOp<T, S, D> op;
            op.scale = static_cast<S>(scale);
            gridTransformBinary_< TransformPolicy<S> >(globPtr<T>(src1), globPtr<T>(src2), globPtr<D>(dst), op, stream);
        }
    }
}

void mulMat(const GpuMat& src1, const GpuMat& src2, GpuMat& dst, const GpuMat&, double scale, Stream& stream, int)
{
    typedef void (*func_t)(const GpuMat& src1, const GpuMat& src2, const GpuMat& dst, double scale, Stream& stream);
    static const func_t funcs[7][7] =
    {
        {
            mulMatImpl<uchar, float, uchar>,
            mulMatImpl<uchar, float, schar>,
            mulMatImpl<uchar, float, ushort>,
            mulMatImpl<uchar, float, short>,
            mulMatImpl<uchar, float, int>,
            mulMatImpl<uchar, float, float>,
            mulMatImpl<uchar, double, double>
        },
        {
            mulMatImpl<schar, float, uchar>,
            mulMatImpl<schar, float, schar>,
            mulMatImpl<schar, float, ushort>,
            mulMatImpl<schar, float, short>,
            mulMatImpl<schar, float, int>,
            mulMatImpl<schar, float, float>,
            mulMatImpl<schar, double, double>
        },
        {
            0 /*mulMatImpl<ushort, float, uchar>*/,
            0 /*mulMatImpl<ushort, float, schar>*/,
            mulMatImpl<ushort, float, ushort>,
            mulMatImpl<ushort, float, short>,
            mulMatImpl<ushort, float, int>,
            mulMatImpl<ushort, float, float>,
            mulMatImpl<ushort, double, double>
        },
        {
            0 /*mulMatImpl<short, float, uchar>*/,
            0 /*mulMatImpl<short, float, schar>*/,
            mulMatImpl<short, float, ushort>,
            mulMatImpl<short, float, short>,
            mulMatImpl<short, float, int>,
            mulMatImpl<short, float, float>,
            mulMatImpl<short, double, double>
        },
        {
            0 /*mulMatImpl<int, float, uchar>*/,
            0 /*mulMatImpl<int, float, schar>*/,
            0 /*mulMatImpl<int, float, ushort>*/,
            0 /*mulMatImpl<int, float, short>*/,
            mulMatImpl<int, float, int>,
            mulMatImpl<int, float, float>,
            mulMatImpl<int, double, double>
        },
        {
            0 /*mulMatImpl<float, float, uchar>*/,
            0 /*mulMatImpl<float, float, schar>*/,
            0 /*mulMatImpl<float, float, ushort>*/,
            0 /*mulMatImpl<float, float, short>*/,
            0 /*mulMatImpl<float, float, int>*/,
            mulMatImpl<float, float, float>,
            mulMatImpl<float, double, double>
        },
        {
            0 /*mulMatImpl<double, double, uchar>*/,
            0 /*mulMatImpl<double, double, schar>*/,
            0 /*mulMatImpl<double, double, ushort>*/,
            0 /*mulMatImpl<double, double, short>*/,
            0 /*mulMatImpl<double, double, int>*/,
            0 /*mulMatImpl<double, double, float>*/,
            mulMatImpl<double, double, double>
        }
    };

    const int sdepth = src1.depth();
    const int ddepth = dst.depth();

    CV_DbgAssert( sdepth <= CV_64F && ddepth <= CV_64F );

    GpuMat src1_ = src1.reshape(1);
    GpuMat src2_ = src2.reshape(1);
    GpuMat dst_ = dst.reshape(1);

    const func_t func = funcs[sdepth][ddepth];

    if (!func)
        CV_Error(cv::Error::StsUnsupportedFormat, "Unsupported combination of source and destination types");

    func(src1_, src2_, dst_, scale, stream);
}

namespace
{
    template <typename T>
    struct MulOpSpecial : binary_function<T, float, T>
    {
        __device__ __forceinline__ T operator ()(const T& a, float b) const
        {
            typedef typename VecTraits<T>::elem_type elem_type;

            T res;

            res.x = saturate_cast<elem_type>(a.x * b);
            res.y = saturate_cast<elem_type>(a.y * b);
            res.z = saturate_cast<elem_type>(a.z * b);
            res.w = saturate_cast<elem_type>(a.w * b);

            return res;
        }
    };
}

void mulMat_8uc4_32f(const GpuMat& src1, const GpuMat& src2, GpuMat& dst, Stream& stream)
{
    gridTransformBinary(globPtr<uchar4>(src1), globPtr<float>(src2), globPtr<uchar4>(dst), MulOpSpecial<uchar4>(), stream);
}

void mulMat_16sc4_32f(const GpuMat& src1, const GpuMat& src2, GpuMat& dst, Stream& stream)
{
    gridTransformBinary(globPtr<short4>(src1), globPtr<float>(src2), globPtr<short4>(dst), MulOpSpecial<short4>(), stream);
}

//------- jwootan cuda experiment ----------------------
// Naive matrix multiplication kernel using global memory
__global__ void mult_global(int arraySize, float* src1, float* src2, float* dst){
    for (int i = blockIdx.x * blockDim.x + threadIdx.x; i < arraySize; i += blockDim.x * gridDim.x) 
     {
        dst[i] = src1[i] * src2[i];
     }
}

// Naive matrix multiplication kernel using register memory
__global__ void mult_reg(int arraySize, float* src1, float* src2, float* dst){
    for (int i = blockIdx.x * blockDim.x + threadIdx.x; i < arraySize; i += blockDim.x * gridDim.x) 
     {
        float reg = src1[i] * src2[i];
        dst[i] = reg;
     }
}

//Optimized multiplication using shared memory and loop unrolling
__global__ void mult_shared(int N, float* src1, float* src2, float* dst){

    extern __shared__ float src1_tile[BLOCK_SIZE][BLOCK_SIZE];
    extern __shared__ float src2_tile[BLOCK_SIZE][BLOCK_SIZE];

    float tmp = 0;
    int i;
    int j;

    #pragma unroll
    for(int tileIdx = 0; tileIdx < (N/blockDim.x - 1); tileIdx++){
        i = blockIdx.y * blockDim.y + threadIdx.y;
        j = tileIdx * blockDim.x + threadIdx.x;
        
        src1_tile[threadIdx.y][threadIdx.x] = src1[i*N+j];
        src2_tile[threadIdx.y][threadIdx.x] = src2[i*N+j];
        __syncthreads();

        #pragma unroll
        for(int k = 0; k < gridDim.x; k++){
            tmp += src1_tile[threadIdx.y][k] * src2_tile[k][threadIdx.x];
        }
        __syncthreads();
    }

    i = blockIdx.y * blockDim.y + threadIdx.y;
    j = blockIdx.x * blockDim.x + threadIdx.x;
    dst[i*N+j]= tmp;
}

//Allocates necessery memory for CUDA kernel calls and selects desired kernel from provided parameter type
void mulMatExperiment(float* src1, float* src2, float* dst, size_t arraySize, int rows, int cols, CUDA_MEM_TYPE memType){
    float *cudaInput1;
    float *cudaInput2;
    float *cudaOutput;

	cudaMalloc((void **)&cudaInput1, arraySize);
	cudaMalloc((void **)&cudaInput2, arraySize);
    cudaMalloc((void **)&cudaOutput, arraySize);

    cudaMemcpy(cudaInput1, src1, arraySize, cudaMemcpyHostToDevice); 
    cudaMemcpy(cudaInput2, src2, arraySize, cudaMemcpyHostToDevice); 

    int threadCount = 1024;
    int blocks = threadCount / 256;

    switch(memType){
        case cv::cuda::REGISTER:
            mult_reg<<<blocks, threadCount>>>(arraySize/sizeof(float), cudaInput1, cudaInput2, cudaOutput);
            break;
        case cv::cuda::SHARED:
            mult_shared<<<blocks, threadCount>>>(cols, cudaInput1, cudaInput2, cudaOutput);
            break;
        default:
            mult_global<<<blocks, threadCount>>>(arraySize/sizeof(float), cudaInput1, cudaInput2, cudaOutput);
    }


    cudaThreadSynchronize();

    cudaMemcpy(dst, cudaOutput, arraySize, cudaMemcpyDeviceToHost);

	cudaFree(cudaInput1);
	cudaFree(cudaInput2);
    cudaFree(cudaOutput);
}

//Sets required arguments and memory needed for CUBLAS sgemm
void sgmmNaive(float* _src1, float* _src2, float* _dst, int rows, int cols){
    cublasInit();
    
    float* cudaA;
    float* cudaB;
    float* cudaOut;

    cublasAlloc(rows*cols,sizeof(float),(void**)&cudaA);
    cublasAlloc(rows*cols,sizeof(float),(void**)&cudaB);
    cublasAlloc(rows*cols,sizeof(float),(void**)&cudaOut);

    cublasSetMatrix(rows,cols,sizeof(float),_src1,rows,cudaA,rows);
    cublasSetMatrix(cols,rows,sizeof(float),_src2,cols,cudaB,cols);
    
    cublasSgemm('n','n',rows,rows,cols,1,cudaA,rows,cudaB,cols,0,cudaOut,rows);

    cudaThreadSynchronize();

    cublasGetMatrix(rows,rows,sizeof(float),cudaOut,rows,_dst,rows);

    cublasFree(cudaA);
    cublasFree(cudaB);
    cublasFree(cudaOut);
    cublasShutdown();
}
//--------------------------------------------------------------

#endif
