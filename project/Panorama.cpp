#include <iostream>
#include <vector>
#include "opencv2/opencv.hpp"
#include "opencv2/core/cuda.hpp"
#include <opencv2/stitching.hpp>
#include <opencv2/core/mat.hpp>
#include <opencv2/core/utils/logger.hpp>
#include <time.h>
#include <string>
#include <dirent.h>

int main (int argc, char* argv[])
{
    /*
        command line arguments
        Panorama cpu|cvgpu|cublas|global|register|shared  #_of_runs image_dir  (--cudawarp optional) (--cudaconvolve optional)

        ex. 100 runs with global multiplipication kernel and cuda warp enabled w/ images located in the local "images" directory
        Panorama global 100 ./images --cudawarp
    */

    float total = 0;

    std::string runType = "cpu";
    int test_runs = 1;
    bool cudaConvolve = false;
    bool cudaWarp = false;
    const char* imgDirPath;

    if(argc >= 4){
        runType = argv[1];
        test_runs = atoi(argv[2]);
        imgDirPath = argv[3];
    } else {
        std::cout << "Please provide runtime arguments in the following format:" << std::endl;
        std::cout << "Panorama cpu|cvgpu|cublas|global|register|shared  #_of_runs image_dir (--cudawarp optional) (--cudaconvolve optional)" << std::endl;
        return 0;
    }

    for(int i = 0; i < argc; i++){
        if(std::string(argv[i]) == "--cudawarp"){
            cudaWarp = true;
        } else if (std::string(argv[i]) == "--cudaconvolve"){
            cudaConvolve = true;
        }
    }

    std::vector<cv::Mat> input;

    DIR *dr;
    struct dirent *en;
    dr = opendir(imgDirPath);
    if (dr) {
        while ((en = readdir(dr)) != NULL) {
            std::string fileName = std::string(en->d_name);
            if(fileName != "out.jpg" && fileName != "." && fileName != ".."){
                std::string filePath = imgDirPath + std::string("/") + fileName;
                input.push_back(cv::imread(filePath));
            }
        }
        closedir(dr);
    }

    cv::Mat pano;
    cv::Ptr<cv::Stitcher> stitcher = cv::Stitcher::create(cv::Stitcher::PANORAMA, cudaWarp, cudaConvolve);
    int errorCount = 0;
    for(int i = 0; i < test_runs; i++){
        try{
            clock_t time = clock();
            cv::Stitcher::Status status = stitcher->stitch(input, pano, runType);
            time = clock() - time;
            float timeSec = ((float) time) / CLOCKS_PER_SEC;
            std::cout << "\rRun " << i+1 << std::flush;
            total += timeSec;
            errorCount = 0;
        } catch(const std::exception& e){
            i--; 
            errorCount++;
        }

        if(errorCount == 5){
            std::cout << "Unexpected Exception" << std::endl;
            return EXIT_FAILURE;
        }
    }

    std::cout << "\nAverage Runtime: " << total/test_runs << std::endl;

    cv::imwrite(imgDirPath + std::string("/out.jpg"), pano);

    return EXIT_SUCCESS;
}