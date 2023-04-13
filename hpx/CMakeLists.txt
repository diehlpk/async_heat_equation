cmake_minimum_required(VERSION 3.20)

project(heat
    DESCRIPTION  "1D heat equation solver in HPX"
    LANGUAGES CXX)

# Add own cmake scripts
list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake/")

# Set director for all exectuables
set(EXECUTABLE_OUTPUT_PATH "${PROJECT_BINARY_DIR}/bin")

#HPX
find_package(HPX REQUIRED)

add_hpx_executable(heat SOURCES heat.cxx)
add_hpx_executable(heat-fast SOURCES heat-fast.cxx)


