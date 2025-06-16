# CONTRIBUTING.md

## Contributing to MINTutil

We welcome contributions! This guide will help you get started.

### ? Quick Start

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### ? Before You Begin

#### Prerequisites
- Python 3.9+
- Git
- Basic understanding of Python and Streamlit
- Familiarity with our [NeoMINT Coding Practices](docs/neomint-coding-practices.md)

#### Setup Development Environment
```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/MINTutil.git
cd MINTutil

# Create virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
pip install -r requirements-dev.txt

# Install pre-commit hooks
pre-commit install
```

### ? Development Guidelines

#### Code Standards
All contributions must follow our [NeoMINT Coding Practices v0.2](docs/neomint-coding-practices.md):

1. **File Structure**
   - Maximum 500 lines per file
   - One responsibility per module
   - Clear separation of concerns

2. **Naming Conventions**
   - PowerShell functions: `PascalCase`
   - Python functions: `snake_case`
   - Variables: `camelCase` (PS) / `snake_case` (Python)
   - Files: `kebab-case`

3. **Documentation**
   - Every file needs a proper metadata block
   - Complex logic requires explanatory comments
   - All functions need docstrings

4. **Testing**
   - Write tests for new features
   - Ensure existing tests pass
   - Aim for >80% coverage

#### Metadata Block Example
```python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Module Name: Brief description

Detailed explanation of functionality.

Author: Your Name
Date: YYYY-MM-DD
Version: X.Y.Z
Dependencies: List required packages
"""
```

### ? Pull Request Process

1. **Check Compliance**
   ```powershell
   .\scripts\check-neomint-compliance.ps1
   ```

2. **Run Tests**
   ```bash
   pytest tests/ -v
   ```

3. **Update Documentation**
   - Add/update docstrings
   - Update README if needed
   - Document in `docs/` for major features

4. **PR Template**
   ```markdown
   ## Description
   Brief description of changes

   ## Type of Change
   - [ ] Bug fix
   - [ ] New feature
   - [ ] Breaking change
   - [ ] Documentation update

   ## Testing
   - [ ] Tests pass locally
   - [ ] Added new tests
   - [ ] NeoMINT compliance checked

   ## Checklist
   - [ ] Code follows project style
   - [ ] Self-review completed
   - [ ] Comments added for complex parts
   - [ ] Documentation updated
   ```

### ? Creating New Tools

Tools are modular components in MINTutil. To create one:

1. **Create tool directory**
   ```
   tools/
   ??? your-tool/
       ??? tool.meta.yaml
       ??? ui.py
       ??? requirements.txt
       ??? README.md
   ```

2. **Define metadata** (`tool.meta.yaml`):
   ```yaml
   name: Your Tool Name
   version: 1.0.0
   description: Brief description
   author: Your Name
   icon: ?
   ```

3. **Implement UI** (`ui.py`):
   ```python
   """Tool UI implementation."""
   
   def render():
       """Main render function called by MINTutil."""
       import streamlit as st
       st.title("Your Tool")
       # Implementation
   ```

See [Tool Development Guide](docs/tool-development.md) for details.

### ? Reporting Issues

Use GitHub Issues with:
- Clear, descriptive title
- Steps to reproduce
- Expected vs actual behavior
- System information
- Error messages/logs

### ? Communication

- **Issues**: Bug reports and feature requests
- **Discussions**: General questions and ideas
- **Pull Requests**: Code contributions

### ? Areas for Contribution

- **New Tools**: Data analysis, visualization, utilities
- **Documentation**: Tutorials, examples, translations
- **Testing**: Unit tests, integration tests
- **UI/UX**: Streamlit components, themes
- **Performance**: Optimization, caching
- **Accessibility**: Screen reader support, keyboard navigation

### ?? License

By contributing, you agree that your contributions will be licensed under the MIT License.

### ? Thank You!

Every contribution helps make MINTutil better. We appreciate your time and effort!

---
Questions? Create an issue with the `question` label.
