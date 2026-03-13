# Security Policy

**Version** : 1.0.0
**Date** : 2026-03-13
**Author** : David LECONTE (IBM WW|Tiger Team - Watsonx.Data GPS)

---

## 📋 Table of Contents

- [Supported Versions](#supported-versions)
- [Reporting a Vulnerability](#reporting-a-vulnerability)
- [Security Scanning](#security-scanning)
- [Best Practices](#best-practices)
- [Secure Configuration](#secure-configuration)
- [Security Metrics](#security-metrics)

---

## 🛡️ Supported Versions

| Version | Supported | Notes |
| ------- | --------- | ----- |
| `main`  | ✅ Yes | Active development |
| `develop` | ✅ Yes | Integration branch |
| Older versions | ❌ No | Upgrade required |

---

## 🚨 Reporting a Vulnerability

### How to Report

If you discover a security vulnerability, please report it responsibly:

1. **Email** : `<david.leconte1@ibm.com>`
2. **Subject** : `[SECURITY] ARKEA POC - Vulnerability Report`

### What to Include

- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

### Response Timeline

| Stage | Timeline |
|-------|----------|
| Acknowledgment | 24-48 hours |
| Initial Assessment | 3-5 business days |
| Fix Development | Depends on severity |
| Disclosure | After fix is deployed |

---

## 🔍 Security Scanning

This project uses automated security scanning:

### SAST (Static Application Security Testing)

| Tool | Target | Frequency |
|------|--------|-----------|
| **Bandit** | Python code | Every push |
| **ShellCheck** | Shell scripts | Every push |

### SCA (Software Composition Analysis)

| Tool | Target | Frequency |
|------|--------|-----------|
| **Safety** | Python dependencies | Every push |
| **Trivy** | Container images | On container changes |

### Secrets Detection

| Tool | Target | Frequency |
|------|--------|-----------|
| **detect-secrets** | All files | Every push |

### Running Locally

```bash
# Run all security checks
make security

# Or individually:
bandit -r . -x ./binaire,./software
shellcheck scripts/**/*.sh
safety check -r requirements.txt
detect-secrets scan --baseline .secrets.baseline
```

---

## ✅ Best Practices

### Secrets Management

```bash
# ✅ DO: Use environment variables
export HCD_HOST="localhost"
export HCD_PORT="9042"

# ❌ DON'T: Hardcode secrets
# HCD_HOST = "localhost"  # Wrong!
```

### Configuration Files

```bash
# ✅ DO: Use template files
cp .env.example .env
# Edit .env with your values

# ❌ DON'T: Commit .env files
# .env is in .gitignore
```

### API Keys & Tokens

```bash
# ✅ DO: Use environment variables or secure vault
export HF_API_KEY="your_token_here"  # pragma: allowlist secret

# ❌ DON'T: Hardcode in source code
# API_KEY = "sk-xxxxx"  # Never do this!  # pragma: allowlist secret
```

---

## 🔒 Secure Configuration

### Podman Isolation

This project uses **Podman** for containerized deployment with strict isolation:

- **Network**: Dedicated subnet `10.89.10.0/24`
- **Ports**: Isolated range `9100-9199`
- **Resources**: Limited to 4 CPUs / 8GB RAM
- **Labels**: All resources tagged `project=arkea`

See `PODMAN_RULES.md` for mandatory compliance requirements.

### Pre-commit Hooks

Security-focused pre-commit hooks are configured:

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/Yelp/detect-secrets
    hooks:
      - id: detect-secrets
```

Install with:

```bash
pre-commit install
```

### Secrets Baseline

Manage secrets detection baseline:

```bash
# Update baseline
detect-secrets scan --baseline .secrets.baseline

# Audit baseline
detect-secrets audit .secrets.baseline
```

---

## 📊 Security Metrics

| Metric | Target | Current |
|--------|--------|---------|
| Known vulnerabilities | 0 | ✅ |
| Secrets in code | 0 | ✅ |
| Critical findings (Bandit) | 0 | ✅ |
| Outdated dependencies | < 5 | ✅ |

---

## 🔗 Related Documents

- [Podman Isolation Rules](PODMAN_RULES.md)
- [Contributing Guide](CONTRIBUTING.md)
- [Code of Conduct](CODE_OF_CONDUCT.md)

---

## 📞 Contact

For security-related questions:

- **Security Team** : `<david.leconte1@ibm.com>`
- **Project Owner** : David LECONTE (IBM WW|Tiger Team)

---

**Last Updated** : 2026-03-13
