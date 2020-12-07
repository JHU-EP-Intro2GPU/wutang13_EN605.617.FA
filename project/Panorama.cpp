#include <iostream>
#include <vector>
#include "opencv2/opencv.hpp"
#include "opencv2/core/cuda.hpp"
#include <opencv2/stitching.hpp>
#include <opencv2/core/mat.hpp>
#include <opencv2/core/utils/logger.hpp>
#include <time.h>
#include <string>

#define TEST_RUNS 200

int main (int argc, char* argv[])
{

    cv::Mat img1 = cv::imread("images/img1.jpg");
    cv::Mat img2 = cv::imread("images/img2.jpg");
    cv::Mat img3 = cv::imread("images/img3.jpg");

    std::vector<cv::Mat> input{ img1,img2,img3};

    cv::Mat pano;
    cv::Ptr<cv::Stitcher> stitcher = cv::Stitcher::create();

    float total = 0;

    std::string runType = "cpu";

    /*
        Valid runtime flags

        cpu:
        cvgpu:
        cublas:
        global:
        register:
    */
    if(argc > 1){
        runType = argv[1];
    }

    for(int i = 0; i < TEST_RUNS; i++){
        try{
            clock_t time = clock();
            cv::Stitcher::Status status = stitcher->stitch(input, pano, runType);
            time = clock() - time;
            float timeSec = ((float) time) / CLOCKS_PER_SEC;
            std::cout << "\r Run " << i+1 << std::flush;
            total += timeSec;
        } catch(const std::exception& e){
            i--; 
        }
    }

    std::cout << "\nAverage Runtime: " << total/TEST_RUNS << std::endl;

    cv::imwrite("images/out.jpg", pano);

    return EXIT_SUCCESS;
}