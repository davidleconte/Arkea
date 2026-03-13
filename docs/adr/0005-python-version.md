# ADR-0005: Python Version and Tooling Selection

## Status

Accepted

## Context

The ARKEA POC uses Python for utility scripts, testing infrastructure, and data processing helpers. We need to select:

1. An appropriate Python version
2. A dependency management approach
3. Code quality tooling

## Decision

We will use **Python 3.9+** with the following tooling stack:

| Component | Tool | Version |
|-----------|------|---------|
| Python | CPython | 3.9+ |
| Formatting | Black | 24.10.0 |
| Import sorting | isort | 5.13.2 |
| Linting | flake8 | 7.1.1 |
| Type checking | mypy | 1.14.1 |
| Security | bandit | 1.7.0 |
| Testing | pytest | 7.4.0+ |
| Coverage | pytest-cov | 4.1.0+ |
| Pre-commit | pre-commit | 3.4.0+ |

## Rationale

### Python 3.9+

- **Type hints**: Full support for modern type hinting features
- **Performance**: Improved performance over 3.8 and earlier
- **EOL**: Supported until October 2025 (extended by 3.10+ availability)
- **Compatibility**: All required packages support 3.9+

### Tooling Selection

- **Black**: Industry-standard formatter, eliminates style debates
- **isort**: Automatic import sorting, integrates with Black
- **flake8**: Lightweight linting, catches common errors
- **mypy**: Static type checking, improves code quality
- **bandit**: Security-focused linting for Python
- **pytest**: Modern testing framework with fixtures and parametrization

## Consequences

### Positive

- Consistent code style across the project
- Automated quality checks via pre-commit hooks
- Type safety with mypy integration
- Security scanning built into CI/CD

### Negative

- Requires Python 3.9+ environment
- Pre-commit hooks add time to commits

## Implementation

All configuration is centralized in `pyproject.toml`:

```toml
[project]
requires-python = ">=3.9"

[project.optional-dependencies]
dev = [
    "pytest>=7.4.0",
    "pytest-cov>=4.1.0",
    "black>=23.0.0",
    "isort>=5.12.0",
    "flake8>=6.0.0",
    "mypy>=1.0.0",
    "bandit>=1.7.0",
    "pre-commit>=3.4.0",
]
```

## References

- [Python 3.9 Release Schedule](https://www.python.org/dev/peps/pep-0596/)
- [pyproject.toml Specification](https://packaging.python.org/en/latest/specifications/pyproject-toml/)

## Date

2026-03-13
