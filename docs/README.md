# ESMF_IO Documentation

This directory contains the documentation for the ESMF_IO Unified Component.

## Overview

ESMF_IO is a unified component that combines the functionality of both input (ExtData equivalent) and output (History equivalent) operations within a single ESMF-compliant component. This documentation provides comprehensive information for users, developers, and administrators.

## Documentation Structure

The documentation is organized into several categories:

### User Documentation

- [Getting Started](user/getting_started.md) - Introduction and basic usage
- [Configuration Guide](user/configuration_guide.md) - How to configure ESMF_IO
- [Examples](user/examples.md) - Practical usage examples

### Developer Documentation

- [API Reference](developer/api_reference.md) - Detailed API documentation
- [Architecture Guide](developer/architecture.md) - System architecture overview
- [Testing Guide](developer/testing.md) - How to test ESMF_IO

### Technical Documentation

- [Performance Analysis](technical/performance_analysis.md) - Performance characteristics and optimization
- [Data Flow Documentation](technical/data_flow.md) - Data flow diagrams and explanations
- [Memory Management](technical/memory_management.md) - Memory usage and management

### Reference Documentation

- [Configuration Parameters](reference/configuration_parameters.md) - Detailed configuration parameter reference
- [Module Dependencies](reference/module_dependencies.md) - Module dependency relationships
- [ESMF Integration](reference/esmf_integration.md) - Integration with ESMF
- [NUOPC Integration](reference/nuopc_integration.md) - Integration with NUOPC

### Release Documentation

- [System Requirements](release/system_requirements.md) - Hardware and software requirements
- [Installation Guide](release/installation.md) - How to install ESMF_IO
- [Release Notes](release/release_notes.md) - Release history and changes
- [License Information](release/license.md) - Licensing details

## Building Documentation

### Requirements

To build the documentation, you need:

1. Python 3.6 or newer
2. MkDocs
3. Material for MkDocs theme
4. Markdown Extra Data plugin

### Installation

Install the required packages:

```bash
pip install -r requirements.txt
```

### Building

To build the documentation:

```bash
./build_docs.sh build
```

### Serving Locally

To serve the documentation locally for development:

```bash
./build_docs.sh serve
```

Then open your browser to http://localhost:8000

### Deploying

To deploy the documentation to GitHub Pages:

```bash
./build_docs.sh deploy
```

## Contributing

We welcome contributions to improve the ESMF_IO documentation. Please follow these guidelines:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## Support

For support with ESMF_IO documentation:

1. [GitHub Issues](https://github.com/bbakernoaa/ESMFIO/issues) - Report bugs or request features
2. [Discussion Forum](https://github.com/bbakernoaa/ESMFIO/discussions) - Ask questions and discuss topics
3. Email: esmf-io-support@ucar.edu

## License

The ESMF_IO documentation is distributed under the Apache License, Version 2.0. See [LICENSE](release/license.md) for more information.
