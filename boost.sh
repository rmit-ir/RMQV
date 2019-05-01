#!/bin/bash

echo "This script will download and compile Boost, and store it in the local dir."
echo "Use this script if you are having issues with your system's version of Boost, or don't have it installed."
echo "This should take about 30mins."
echo "If this is not your intention, press CTRL+C to stop, or any key to continue."
read

echo "Downloading Boost 1.70.0" 
# Don't download the git repo, the tarball is already ~100MB.
mkdir -p boost
cd boost

wget https://dl.bintray.com/boostorg/release/1.70.0/source/boost_1_70_0.tar.gz

echo "Extracting Boost"
tar -xzf boost_1_70_0.tar.gz

echo "Executing Boost Bootstrap Script"
cd boost_1_70_0
./bootstrap.sh

echo "Executing b2 script"
./b2

cd ../..
echo "Boost is now compiled and ready."
echo "Now when you call cmake you can use:"
echo "cmake .. -DBoost_NO_BOOST_CMAKE=TRUE -DBOOST_ROOT=$(pwd)/boost/boost_1_70_0"
echo "Note that -DBoost_NO_BOOST_CMAKE=TRUE is a fix for Red Hat linux, where any changes in Boost paths are ignored otherwise."

echo "\nYou may be able to set the variables inside the CMakeLists.txt file as well, if you don't want to supply it to cmake all the time."
echo "Whether these changes are propagated to cmake children is unknown to me, YMMV."
