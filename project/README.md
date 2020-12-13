# Panorama Project

This project is an attempt to experimentally determine the efficency of different implementationa of matrix multiplication in CUDA. Specifically, this project is looking to improve the performance of the OpenCV Image Stitching algorithms.

To run this experiment please download the source code of OpenCV version 4.5 and the latest version of the opencv_contrib project.

[opencv repo](https://github.com/opencv/opencv)  
[opencv_contrib repo](https://github.com/opencv/opencv_contrib)

To build library from source follow the instructions located at the link below. The only difference being instead of using the `cmake` command directly place the `build_opencv.sh` script in the build folder of the opencv source code and run it.

[build instructions linux](https://docs.opencv.org/master/d7/d9f/tutorial_linux_install.html)

To use the kernels added to OpenCV from this project replace the files in opencv with their matching files in the opencv_changes folder provided (following the same pat for each file). Do likewise with the files in opencv_contrib_changes.

Once OpenCV has been built with CUDA available to test run the following commands from the project directory.
```
cmake .
make
./Panorama cvgpu 1 images
```
The Panorama executable accepts the following command line arguments
```
Panorama (cpu||cvgpu||global||register||shared||cublass) (# of iterations to run) (path to image folder) (optional --cudaconvolve) (optional --cudawarp)
```

The `test.sh` script can also be run to see the comparative peformance of each of the implementations available for testing.
