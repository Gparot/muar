cmake_minimum_required(VERSION 3.14)
project(sudoku_clique LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 14)
find_package(BitGraph CONFIG REQUIRED)

add_executable(sudoku_clique main.cpp)
target_link_libraries(sudoku_clique PRIVATE
    BitGraph::graph BitGraph::bitscan BitGraph::utils)