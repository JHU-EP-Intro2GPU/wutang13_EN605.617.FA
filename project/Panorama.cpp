#include <iostream>
#include <vector>
#include "opencv2/opencv.hpp"
#include "opencv2/core/cuda.hpp"
#include <opencv2/stitching.hpp>
#include <opencv2/core/mat.hpp>
#include <opencv2/core/utils/logger.hpp>
#include <time.h>

#define TEST_RUNS 10

int main (int argc, char* argv[])
{
    cv::Mat img1 = cv::imread("images/img1.jpg");
    cv::Mat img2 = cv::imread("images/img2.jpg");
    cv::Mat img3 = cv::imread("images/img3.jpg");
    cv::Mat img4 = cv::imread("images/img4.jpg");
    cv::Mat img5 = cv::imread("images/img5.jpg");
    cv::Mat img6 = cv::imread("images/img6.jpg");


    std::vector<cv::Mat> input{img1, img2, img3,img4,img5,img6};

    cv::Mat pano;
    cv::Ptr<cv::Stitcher> stitcher = cv::Stitcher::create();

    float total = 0;

    for(int i = 0; i < TEST_RUNS; i++){
        clock_t time = clock();
        cv::Stitcher::Status status = stitcher->stitch(input, pano);
        time = clock() - time;
        float timeSec = ((float) time) / CLOCKS_PER_SEC;
        std::cout << timeSec << std::endl;
        total += timeSec;
    }

    std::cout << "Average Runtime: " << total/TEST_RUNS << std::endl;


    cv::imwrite("images/out.jpg", pano);

    return EXIT_SUCCESS;
}