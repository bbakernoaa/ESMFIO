# CMakeLists.txt for Single Model ESMF_IO NUOPC Example

# Set minimum CMake version
cmake_minimum_required(VERSION 3.20)

# Project name
project(SingleModelESMFIODemo LANGUAGES Fortran)

# Include directories
include_directories(${CMAKE_CURRENT_SOURCE_DIR})
include_directories(${ESMF_INCLUDE_DIRS})
include_directories(${CMAKE_SOURCE_DIR}/src)
include_directories(${CMAKE_BINARY_DIR}/src)  # Module files are in the src binary directory

# Add executable
add_executable(esmf_io_single_model_demo
    Driver.F90
)

# Set properties for the executable
set_target_properties(esmf_io_single_model_demo PROPERTIES
    Fortran_MODULE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/modfiles
)

# Link libraries - use the core esmf_io library and required dependencies
target_link_libraries(esmf_io_single_model_demo
    esmf_io  # Core library
    ${ESMF_LIBRARIES}
    MPI::MPI_Fortran
)

# Add dependency on the driver to ensure module files are generated
add_dependencies(esmf_io_single_model_demo esmf_io_driver)

# Compiler-specific flags
if(CMAKE_Fortran_COMPILER_ID MATCHES "GNU")
    set_target_properties(esmf_io_single_model_demo PROPERTIES
        COMPILE_FLAGS "-cpp -ffree-line-length-none"
    )
elseif(CMAKE_Fortran_COMPILER_ID MATCHES "Intel")
    set_target_properties(esmf_io_single_model_demo PROPERTIES
        COMPILE_FLAGS "-fpp"
    )
elseif(CMAKE_Fortran_COMPILER_ID MATCHES "PGI|NVHPC")
    set_target_properties(esmf_io_single_model_demo PROPERTIES
        COMPILE_FLAGS "-Mpreprocess"
    )
endif()

# Installation
install(TARGETS esmf_io_single_model_demo
    RUNTIME DESTINATION bin
)