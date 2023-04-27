cmake_minimum_required(VERSION 3.20)

project(heat_ghosts
    DESCRIPTION  "1D heat equation solver in HPX"
    LANGUAGES CXX)

# Add own cmake scripts
list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake/")

# Set director for all exectuables
set(EXECUTABLE_OUTPUT_PATH "${PROJECT_BINARY_DIR}/bin")

#HPX
find_package(HPX REQUIRED)

add_hpx_executable(heat_ghosts SOURCES heat_ghosts.cxx)


