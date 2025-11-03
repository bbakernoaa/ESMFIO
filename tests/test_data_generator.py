#!/usr/bin/env python3
"""
Test data generator for ESMF_IO NUOPC component.
Creates NetCDF files with sample field data for testing.
"""
import numpy as np
from netCDF4 import Dataset
import os

def create_test_input_data(filename, nx=10, ny=10, time_steps=1):
    """
    Create a test NetCDF file with sample field data.
    
    Parameters:
    - filename: Output NetCDF file name
    - nx, ny: Grid dimensions
    - time_steps: Number of time steps to include
    """
    # Create the NetCDF file
    with Dataset(filename, 'w', format='NETCDF4') as ncfile:
        # Create dimensions
        ncfile.createDimension('time', time_steps)
        ncfile.createDimension('lon', nx)
        ncfile.createDimension('lat', ny)
        
        # Create coordinate variables
        lon = ncfile.createVariable('lon', 'f4', ('lon',))
        lat = ncfile.createVariable('lat', 'f4', ('lat',))
        
        # Set coordinate values
        lon[:] = np.linspace(-180.0, 180.0, nx)
        lat[:] = np.linspace(-90.0, 90.0, ny)
        
        # Create time variable
        time = ncfile.createVariable('time', 'f8', ('time',))
        time.units = 'hours since 2000-01-01 00:00:00'
        time[:] = np.arange(time_steps)
        
        # Create sample field variables
        air_temp = ncfile.createVariable('air_temperature', 'f4', ('time', 'lon', 'lat'))
        air_temp.units = 'K'
        air_temp.long_name = 'Air Temperature'
        
        east_wind = ncfile.createVariable('eastward_wind', 'f4', ('time', 'lon', 'lat'))
        east_wind.units = 'm s-1'
        east_wind.long_name = 'Eastward Wind'
        
        north_wind = ncfile.createVariable('northward_wind', 'f4', ('time', 'lon', 'lat'))
        north_wind.units = 'm s-1'
        north_wind.long_name = 'Northward Wind'
        
        # Generate sample data
        for t in range(time_steps):
            # Create some realistic but simple test data patterns
            lons, lats = np.meshgrid(lon[:], lat[:], indexing='ij')
            
            # Air temperature: simple pattern with variation
            air_temp[t, :, :] = 280.0 + 20.0 * np.sin(lats) * np.cos(lons)
            
            # Eastward wind: zonal pattern
            east_wind[t, :, :] = 5.0 + 3.0 * np.sin(lats) * np.cos(lons)
            
            # Northward wind: meridional pattern
            north_wind[t, :, :] = 2.0 + 2.0 * np.cos(lats) * np.sin(lons)
    
    print(f"Created test input data file: {filename}")

def create_test_output_data(filename, nx=10, ny=10, time_steps=1, scale_factor=2.0):
    """
    Create a test NetCDF file with scaled field data to match what the app should produce.
    
    Parameters:
    - filename: Output NetCDF file name
    - nx, ny: Grid dimensions
    - time_steps: Number of time steps to include
    - scale_factor: Factor by which input fields were scaled
    """
    # Create the NetCDF file
    with Dataset(filename, 'w', format='NETCDF4') as ncfile:
        # Create dimensions
        ncfile.createDimension('time', time_steps)
        ncfile.createDimension('lon', nx)
        ncfile.createDimension('lat', ny)
        
        # Create coordinate variables
        lon = ncfile.createVariable('lon', 'f4', ('lon',))
        lat = ncfile.createVariable('lat', 'f4', ('lat',))
        
        # Set coordinate values
        lon[:] = np.linspace(-180.0, 180.0, nx)
        lat[:] = np.linspace(-90.0, 90.0, ny)
        
        # Create time variable
        time = ncfile.createVariable('time', 'f8', ('time',))
        time.units = 'hours since 2000-01-01 00:00:00'
        time[:] = np.arange(time_steps)
        
        # Create sample field variables (scaled)
        air_temp = ncfile.createVariable('air_temperature', 'f4', ('time', 'lon', 'lat'))
        air_temp.units = 'K'
        air_temp.long_name = 'Air Temperature'
        
        east_wind = ncfile.createVariable('eastward_wind', 'f4', ('time', 'lon', 'lat'))
        east_wind.units = 'm s-1'
        east_wind.long_name = 'Eastward Wind'
        
        north_wind = ncfile.createVariable('northward_wind', 'f4', ('time', 'lon', 'lat'))
        north_wind.units = 'm s-1'
        north_wind.long_name = 'Northward Wind'
        
        # Generate scaled sample data
        for t in range(time_steps):
            # Create some realistic but simple test data patterns
            lons, lats = np.meshgrid(lon[:], lat[:], indexing='ij')
            
            # Air temperature: simple pattern with variation, scaled
            air_temp[t, :, :] = scale_factor * (280.0 + 20.0 * np.sin(lats) * np.cos(lons))
            
            # Eastward wind: zonal pattern, scaled
            east_wind[t, :, :] = scale_factor * (5.0 + 3.0 * np.sin(lats) * np.cos(lons))
            
            # Northward wind: meridional pattern, scaled
            north_wind[t, :, :] = scale_factor * (2.0 + 2.0 * np.cos(lats) * np.sin(lons))
    
    print(f"Created test output data file (scaled by {scale_factor}): {filename}")

if __name__ == "__main__":
    # Create test directories if they don't exist
    os.makedirs("tests/data", exist_ok=True)
    
    # Create input test data
    create_test_input_data("tests/data/input_test.nc", nx=20, ny=20, time_steps=1)
    
    # Create expected output test data (with scale factor of 2.0)
    create_test_output_data("tests/data/expected_output.nc", nx=20, ny=20, time_steps=1, scale_factor=2.0)