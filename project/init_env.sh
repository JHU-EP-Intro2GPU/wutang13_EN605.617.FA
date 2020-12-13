#!/bin/bash
echo "Update cmake g++ and git"
sudo apt update && sudo apt install -y cmake g++ git

# Download and unpack sources
echo "Downloading OpenCV Repo"
git clone https://github.com/opencv/opencv.git
echo "Downloading OpenCV Contrib Repo"
git clone https://github.com/opencv/opencv_contrib.git

echo "Create opencv build directory"
mkdir -p opencv/build

cd opencv_changes

echo "Replacing Modified OpenCV Files"
cp --parents build/build_opencv.sh ../opencv
cp --parents modules/core/include/opencv2/core/cuda.hpp ../opencv
cp --parents modules/features2d/include/opencv2/features2d.hpp ../opencv
cp --parents modules/features2d/src/orb.cpp ../opencv
cp --parents modules/features2d/CMakeLists.txt ../opencv
cp --parents modules/stitching/include/opencv2/stitching/detail/exposure_compensate.hpp ../opencv
cp --parents modules/stitching/include/opencv2/stitching.hpp ../opencv
cp --parents modules/stitching/perf/opencl/perf_stitch.cpp ../opencv
cp --parents modules/stitching/perf/perf_stich.cpp ../opencv
cp --parents modules/stitching/src/exposure_compensate.cpp ../opencv
cp --parents modules/stitching/src/stitcher.cpp ../opencv

cd ../opencv_contrib_changes 

echo "Replacing Modified OpenCV Contrib Files"
cp --parents modules/cudaarithm/include/opencv2/cudaarithm.hpp ../opencv_contrib
cp --parents modules/cudaarithm/src/cuda/mul_mat.cu ../opencv_contrib
cp --parents modules/cudaarithm/src/element_operations.cpp ../opencv_contrib

cd ../opencv/build
echo "Calling build script"
bash build_opencv.sh

echo "Making and installing opencv libraries"
sudo make -j4 && sudo make install
cd ../../

echo "Making test executable"
cmake .
make

echo "Done"