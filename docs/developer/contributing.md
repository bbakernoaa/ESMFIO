# Contributing Guidelines

Thank you for your interest in contributing to the ESMF_IO Unified Component! This document provides guidelines for contributing to the project.

## Overview

ESMF_IO welcomes contributions from the community. Whether you're interested in fixing bugs, adding new features, or improving documentation, your help is appreciated.

## How to Contribute

### Reporting Bugs

If you find a bug in ESMF_IO:

1. Check the [existing issues](https://github.com/ESMF/ESMF_IO/issues) to see if the bug has already been reported
2. If not, [create a new issue](https://github.com/ESMF/ESMF_IO/issues/new) with:
   - A clear and descriptive title
   - A detailed description of the problem
   - Steps to reproduce the issue
   - Expected vs. actual behavior
   - Environment information (OS, compiler, ESMF version, etc.)

### Suggesting Enhancements

To suggest a new feature or enhancement:

1. Check the [existing issues](https://github.com/ESMF/ESMF_IO/issues) to see if the enhancement has already been suggested
2. If not, [create a new issue](https://github.com/ESMF/ESMF_IO/issues/new) with:
   - A clear and descriptive title
   - A detailed description of the proposed enhancement
   - Justification for why the enhancement would be useful
   - Potential implementation approaches (if known)

### Contributing Code

To contribute code to ESMF_IO:

1. Fork the [repository](https://github.com/ESMF/ESMF_IO)
2. Create a new branch for your feature or bugfix
3. Make your changes following the [coding standards](#coding-standards)
4. Add tests for your changes
5. Ensure all tests pass
6. Submit a pull request with a clear description of your changes

## Coding Standards

### Fortran Coding Standards

1. **Style Guide**:
   - Use 2-space indentation
   - Limit lines to 80 characters
   - Use lowercase for keywords and identifiers
   - Use descriptive variable and subroutine names

2. **Module Structure**:
   - Each module should have a clear, focused purpose
   - Public interfaces should be explicitly declared
   - Private procedures should be used for internal implementation details

3. **Error Handling**:
   - Always check return codes from ESMF procedures
   - Use ESMF's error handling mechanisms consistently
   - Provide meaningful error messages

4. **Documentation**:
   - All public interfaces must be documented
   - Use Doxygen-style comments for all subroutines and functions
   - Include examples for complex interfaces

### Git Workflow

1. **Branching**:
   - Use descriptive branch names (e.g., `feature/add-new-input-format`)
   - Keep branches focused on a single feature or bugfix
   - Delete branches after merging

2. **Commit Messages**:
   - Use imperative mood ("Fix bug" not "Fixed bug")
   - Keep the first line under 50 characters
   - Provide detailed explanations in subsequent paragraphs when needed

3. **Pull Requests**:
   - Squash commits to tell a coherent story
   - Ensure the PR description clearly explains the changes
   - Link to related issues when applicable

## Testing Requirements

### Unit Tests

All new code must include appropriate unit tests:

1. **Coverage**: New code should have high test coverage
2. **Edge Cases**: Tests should cover boundary conditions and error cases
3. **Performance**: Performance-critical code should include benchmarks

### Integration Tests

Changes that affect component interactions require integration tests:

1. **Lifecycle Tests**: Test complete component initialization, run, and finalization
2. **Configuration Tests**: Test various configuration scenarios
3. **Error Handling Tests**: Test graceful error handling

### Performance Tests

Performance-sensitive changes require performance tests:

1. **Baseline Comparison**: Compare performance against established baselines
2. **Scalability Tests**: Test performance scaling with problem size and processor count
3. **Regression Detection**: Ensure no performance regressions are introduced

## Documentation Requirements

### Code Documentation

1. **Inline Comments**: Explain complex logic and algorithms
2. **Public Interface Documentation**: Document all public interfaces with:
   - Brief description
   - Parameter descriptions
   - Return value descriptions
   - Error conditions
   - Examples (when appropriate)

### User Documentation

Changes that affect user-facing functionality require documentation updates:

1. **Configuration Guide**: Update configuration documentation when parameters change
2. **Examples**: Add or update examples when functionality changes
3. **Release Notes**: Document user-visible changes in release notes

## Review Process

### Pull Request Review

All pull requests are reviewed by the development team:

1. **Automated Checks**: CI pipeline runs all tests
2. **Code Review**: At least one reviewer examines the code
3. **Documentation Review**: Documentation changes are reviewed
4. **Merge**: Approved pull requests are merged by maintainers

### Review Criteria

Reviewers evaluate pull requests based on:

1. **Correctness**: Does the code work as intended?
2. **Performance**: Are there any performance concerns?
3. **Maintainability**: Is the code easy to understand and modify?
4. **Test Coverage**: Are there adequate tests?
5. **Documentation**: Is the code properly documented?

## Community Guidelines

### Code of Conduct

All contributors are expected to follow the community code of conduct:

1. **Respect**: Treat all contributors with respect
2. **Inclusivity**: Welcome contributions from all backgrounds
3. **Constructive Feedback**: Provide helpful, constructive criticism
4. **Professionalism**: Maintain professional standards in all interactions

### Communication

1. **Issues**: Use GitHub issues for bug reports and feature requests
2. **Discussions**: Use GitHub discussions for general questions and topics
3. **Email**: Contact the development team at esmf-io-support@ucar.edu for private matters

## Development Environment

### Setting Up

To set up a development environment:

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/ESMF/ESMF_IO.git
   cd ESMF_IO
   ```

2. **Install Dependencies**:
   ```bash
   # Install system dependencies
   # (Instructions vary by platform)
   
   # Install ESMF
   # (Follow ESMF installation instructions)
   ```

3. **Build ESMF_IO**:
   ```bash
   mkdir build
   cd build
   cmake .. \
     -DCMAKE_Fortran_COMPILER=mpif90 \
     -DCMAKE_BUILD_TYPE=Debug \
     -DENABLE_TESTS=ON
   make -j$(nproc)
   ```

### Running Tests

To run the test suite:

```bash
# Run all tests
make test

# Or run the test executable directly
./esmf_io_test_runner
```

### Code Formatting

Use the provided formatting script to ensure consistent code style:

```bash
# Format all Fortran files
./scripts/format.sh
```

## Release Process

### Versioning

ESMF_IO follows semantic versioning:

1. **Major**: Breaking changes to public interfaces
2. **Minor**: New features that are backward compatible
3. **Patch**: Bug fixes that are backward compatible

### Release Checklist

Before creating a release:

1. **Testing**: Ensure all tests pass
2. **Documentation**: Update all documentation
3. **Changelog**: Update the changelog with changes since the last release
4. **Version Numbers**: Update version numbers in all relevant files
5. **Tagging**: Create a signed Git tag for the release

## Getting Help

If you need help with contributing:

1. **Documentation**: Read the relevant documentation
2. **Issues**: Search existing issues for similar problems
3. **Discussions**: Ask questions in the discussion forum
4. **Email**: Contact the development team at esmf-io-support@ucar.edu

Thank you for contributing to ESMF_IO! Your contributions help make the project better for everyone.