# CUDA in OpenCV Panoramas

This project is an attempt to experimentally determine the efficency of different implementationa of matrix multiplication in CUDA. Specifically, this project is looking to improve the performance of the OpenCV Image Stitching algorithms.

To run this experiment clone this repo into the home directory and run the `init_env.sh` script. CUDA must already be installed for the initialization to work. It will take a while to build as OpenCV is a fairly large repository. This project will also only work in a linux environment.

The source files that I have modified are located in either either opencv_changes or opencv_contrib_changes. The sections I modified in each of the files are marked with a comment that contains my name:
```
//jwootan
```

Once OpenCV has been built with CUDA available to test run the following commands from the project directory.
```
cmake .
make
./Panorama cvgpu 1 images
```
The Panorama executable accepts the following command line arguments
```
Panorama (cpu||cvgpu||global||register||shared||cublas) (# of iterations to run) (path to image folder) (optional --cudaconvolve) (optional --cudawarp)
```

The `test.sh` script can also be run to see the comparative peformance of each of the implementations available for testing.
