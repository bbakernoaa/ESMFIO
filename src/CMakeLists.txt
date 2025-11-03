# CMake build configuration for ESMF_IO source components
# This file manages the building of the core library components

# Ensure the module directory exists before building
file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/include)

# Define the main ESMF_IO library target
add_library(esmf_io)

# Define source files for the main library
set(ESMF_IO_CORE_SOURCES
ESMF_IO_Component_Mod.F90
ESMF_IO_Config_Params_Mod.F90
ESMF_IO_Config_Mod.F90
ESMF_IO_Input_Mod.F90
ESMF_IO_Output_Mod.F90
ESMF_IO_Parallel_Mod.F90
ESMF_IO_Grid_Config_Mod.F90 # New grid configuration module
ESMF_IO_NUOPC_Mod.F90 # NUOPC module without main program
)

# Set the source files for the library target
target_sources(esmf_io PRIVATE ${ESMF_IO_CORE_SOURCES})

# Set library properties
set_target_properties(esmf_io PROPERTIES
Fortran_MODULE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/include
VERSION ${PROJECT_VERSION}
SOVERSION ${PROJECT_VERSION_MAJOR}
)

# Ensure the module directory exists
file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/include)

# Require C++11 standard for any C components
target_compile_features(esmf_io
PUBLIC
c_std_11
)

# Add ESMF compile options to the target
target_compile_options(esmf_io PRIVATE
$<$<COMPILE_LANGUAGE:Fortran>:${ESMF_Fortran_FLAGS}>
)

# Link required libraries to the main target
target_link_libraries(esmf_io
PUBLIC
ESMF::ESMF
MPI::MPI_Fortran
PRIVATE
Threads::Threads
)

# Handle optional dependencies
if (ENABLE_NETCDF)
if (TARGET NetCDF::NetCDF_Fortran)
target_link_libraries(esmf_io
PUBLIC
NetCDF::NetCDF_Fortran
PRIVATE
NetCDF::NetCDF_C
)
else()
# Fallback to older NetCDF target names or manual linking
target_link_libraries(esmf_io
PUBLIC
${NetCDF_Fortran_LIBRARIES}
PRIVATE
${NetCDF_C_LIBRARIES}
)
target_include_directories(esmf_io
PRIVATE
${NetCDF_Fortran_INCLUDE_DIRS}
${NetCDF_C_INCLUDE_DIRS}
)
endif()
target_compile_definitions(esmf_io
PUBLIC
USE_NETCDF
)
endif()

if (PnetCDF_FOUND)
if (TARGET PnetCDF::PnetCDF_Fortran)
target_link_libraries(esmf_io
PUBLIC
PnetCDF::PnetCDF_Fortran
PRIVATE
PnetCDF::PnetCDF_C
)
else()
# Fallback to older PnetCDF target names or manual linking
target_link_libraries(esmf_io
PUBLIC
${PNETCDF_Fortran_LIBRARIES}
PRIVATE
${PNETCDF_C_LIBRARIES}
)
target_include_directories(esmf_io
PRIVATE
${PNETCDF_Fortran_INCLUDE_DIRS}
${PNETCDF_C_INCLUDE_DIRS}
)
endif()
target_compile_definitions(esmf_io
PUBLIC
USE_PNETCDF
)
endif()

# Set include directories for the target
target_include_directories(esmf_io
PUBLIC
$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
$<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/include>
$<INSTALL_INTERFACE:include>
)

# Create the main executable (NUOPC driver)
add_executable(esmf_io_driver)
target_sources(esmf_io_driver PRIVATE ESMF_IO_Cap.F90)
target_compile_options(esmf_io_driver PRIVATE
$<$<COMPILE_LANGUAGE:Fortran>:${ESMF_Fortran_FLAGS}>
)

# Link the driver to the core library and dependencies
target_link_libraries(esmf_io_driver
PRIVATE
esmf_io  # Use the core library which contains all necessary modules
ESMF::ESMF
MPI::MPI_Fortran
)
# Also link optional dependencies to the driver
if (ENABLE_NETCDF)
if (TARGET NetCDF::NetCDF_Fortran)
target_link_libraries(esmf_io_driver
PRIVATE
NetCDF::NetCDF_Fortran
)
else()
target_link_libraries(esmf_io_driver
PRIVATE
${NetCDF_Fortran_LIBRARIES}
)
endif()
endif()

if (PnetCDF_FOUND)
if (TARGET PnetCDF::PnetCDF_Fortran)
target_link_libraries(esmf_io_driver
PRIVATE
PnetCDF::PnetCDF_Fortran
)
else()
target_link_libraries(esmf_io_driver
PRIVATE
${PNETCDF_Fortran_LIBRARIES}
)
endif()
endif()

# Define installation rules for the libraries and executable
install(TARGETS esmf_io esmf_io_driver
EXPORT ESMF_IO_Targets
LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

# Install source files for development
install(FILES ${ESMF_IO_CORE_SOURCES}
ESMF_IO_Cap.F90  # Include the original file with main program
DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/esmf_io/src
)

# Add tests to ctest if testing is enabled
if (ENABLE_TESTS AND BUILD_TESTING)
add_subdirectory(tests)
endif()
