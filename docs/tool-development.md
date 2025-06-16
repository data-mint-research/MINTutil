# Tool Development Guide

This guide explains how to create custom tools for MINTutil. Tools are modular components that extend MINTutil's functionality.

## Table of Contents

- [Tool Architecture](#tool-architecture)
- [Creating a New Tool](#creating-a-new-tool)
- [Tool Structure](#tool-structure)
- [UI Development](#ui-development)
- [Best Practices](#best-practices)
- [Example Tool](#example-tool)
- [Testing Tools](#testing-tools)
- [Publishing Tools](#publishing-tools)

## Tool Architecture

MINTutil tools follow a plugin-based architecture:

```
tools/
??? your_tool/
    ??? ui.py              # Required: Streamlit UI
    ??? tool.meta.yaml     # Required: Tool metadata
    ??? README.md          # Recommended: Documentation
    ??? requirements.txt   # Optional: Additional dependencies
    ??? config/           # Optional: Configuration files
    ??? scripts/          # Optional: Backend scripts
    ??? tests/            # Optional: Tool-specific tests
```

## Creating a New Tool

### Step 1: Create Tool Directory

```bash
# Create tool directory
mkdir tools/my_awesome_tool

# Navigate to tool directory
cd tools/my_awesome_tool
```

### Step 2: Create Metadata File

Create `tool.meta.yaml`:

```yaml
name: "My Awesome Tool"
description: "A tool that does awesome things"
icon: "?"
version: "1.0.0"
author: "Your Name"
email: "your.email@example.com"
tags:
  - automation
  - data-processing
requirements:
  - pandas>=2.0.0
  - requests>=2.31.0
```

### Step 3: Create UI File

Create `ui.py` with a `render()` function:

```python
import streamlit as st
from pathlib import Path
import sys

# Add tool directory to path for imports
tool_path = Path(__file__).parent
sys.path.append(str(tool_path))

def render():
    """Main render function - required entry point"""
    st.title("? My Awesome Tool")
    
    # Tool description
    st.markdown("""
    Welcome to My Awesome Tool! This tool helps you:
    - Process data efficiently
    - Automate repetitive tasks
    - Generate insights
    """)
    
    # Main functionality
    main_ui()

def main_ui():
    """Main UI logic"""
    # Input section
    with st.container():
        st.header("Input")
        user_input = st.text_area(
            "Enter your data",
            height=200,
            help="Paste your data here"
        )
        
        process_button = st.button(
            "Process Data",
            type="primary",
            disabled=not user_input
        )
    
    # Process data
    if process_button and user_input:
        with st.spinner("Processing..."):
            result = process_data(user_input)
            display_results(result)

def process_data(data):
    """Process the input data"""
    # Add your processing logic here
    return {
        "status": "success",
        "processed": data.upper(),
        "stats": {
            "length": len(data),
            "words": len(data.split())
        }
    }

def display_results(result):
    """Display processing results"""
    st.success("? Processing complete!")
    
    # Display results
    col1, col2 = st.columns(2)
    with col1:
        st.metric("Characters", result["stats"]["length"])
    with col2:
        st.metric("Words", result["stats"]["words"])
    
    # Show processed data
    st.subheader("Processed Data")
    st.code(result["processed"])
    
    # Download button
    st.download_button(
        label="? Download Result",
        data=result["processed"],
        file_name="processed_data.txt",
        mime="text/plain"
    )
```

## Tool Structure

### Required Components

1. **ui.py**: Main UI file with `render()` function
2. **tool.meta.yaml**: Tool metadata

### Optional Components

1. **scripts/**: Backend processing scripts
2. **config/**: Configuration files
3. **data/**: Sample data or resources
4. **tests/**: Unit tests
5. **README.md**: Tool documentation

## UI Development

### Streamlit Components

Use Streamlit components for the UI:

```python
# Input components
text = st.text_input("Label", "default")
number = st.number_input("Number", min_value=0)
date = st.date_input("Date")
file = st.file_uploader("Upload file")

# Display components
st.write("Text")
st.markdown("**Markdown**")
st.code("print('Code')")
st.json({"key": "value"})

# Layout components
col1, col2 = st.columns(2)
with st.expander("More options"):
    st.write("Hidden content")

# Feedback components
st.success("Success!")
st.error("Error!")
st.warning("Warning!")
st.info("Info")
```

### Session State

Use session state for persistent data:

```python
# Initialize state
if 'counter' not in st.session_state:
    st.session_state.counter = 0

# Update state
if st.button("Increment"):
    st.session_state.counter += 1

# Display state
st.write(f"Count: {st.session_state.counter}")
```

### File Handling

Handle file uploads and downloads:

```python
# File upload
uploaded_file = st.file_uploader("Choose a file")
if uploaded_file is not None:
    # Read file
    content = uploaded_file.read()
    st.write(f"File size: {len(content)} bytes")

# File download
data = "Hello, World!"
st.download_button(
    label="Download",
    data=data,
    file_name="output.txt",
    mime="text/plain"
)
```

## Best Practices

### 1. Error Handling

Always handle errors gracefully:

```python
try:
    result = risky_operation()
    st.success("Operation successful!")
except Exception as e:
    st.error(f"Error: {str(e)}")
    st.info("Please check your input and try again.")
```

### 2. Progress Indication

Show progress for long operations:

```python
# Simple spinner
with st.spinner("Processing..."):
    result = long_operation()

# Progress bar
progress_bar = st.progress(0)
for i in range(100):
    progress_bar.progress(i + 1)
    process_item(i)
```

### 3. Input Validation

Validate user input:

```python
def validate_input(text):
    if not text:
        st.error("Input cannot be empty")
        return False
    if len(text) > 10000:
        st.error("Input too long (max 10,000 characters)")
        return False
    return True

if validate_input(user_input):
    process_data(user_input)
```

### 4. Modular Code

Keep code modular and organized:

```python
# Separate concerns
from scripts.processor import DataProcessor
from scripts.validator import InputValidator
from scripts.formatter import OutputFormatter

def render():
    # UI logic only
    data = get_user_input()
    if InputValidator.validate(data):
        result = DataProcessor.process(data)
        OutputFormatter.display(result)
```

## Example Tool

Here's a complete example of a CSV analyzer tool:

```python
import streamlit as st
import pandas as pd
import plotly.express as px
from pathlib import Path

def render():
    st.title("? CSV Analyzer")
    st.markdown("Analyze and visualize CSV data")
    
    # File upload
    uploaded_file = st.file_uploader(
        "Choose a CSV file",
        type=['csv'],
        help="Select a CSV file to analyze"
    )
    
    if uploaded_file is not None:
        # Load data
        df = load_csv(uploaded_file)
        
        if df is not None:
            # Display basic info
            display_info(df)
            
            # Data preview
            display_preview(df)
            
            # Visualizations
            create_visualizations(df)
            
            # Export options
            export_data(df)

def load_csv(file):
    try:
        df = pd.read_csv(file)
        st.success(f"? Loaded {len(df)} rows")
        return df
    except Exception as e:
        st.error(f"Error loading CSV: {str(e)}")
        return None

def display_info(df):
    st.subheader("? Dataset Information")
    col1, col2, col3 = st.columns(3)
    
    with col1:
        st.metric("Rows", len(df))
    with col2:
        st.metric("Columns", len(df.columns))
    with col3:
        st.metric("Memory", f"{df.memory_usage().sum() / 1024:.1f} KB")

def display_preview(df):
    st.subheader("? Data Preview")
    st.dataframe(df.head(10))

def create_visualizations(df):
    st.subheader("? Visualizations")
    
    # Column selection
    numeric_cols = df.select_dtypes(include=['number']).columns.tolist()
    
    if numeric_cols:
        col = st.selectbox("Select column to visualize", numeric_cols)
        
        # Create plots
        col1, col2 = st.columns(2)
        
        with col1:
            fig = px.histogram(df, x=col, title=f"Distribution of {col}")
            st.plotly_chart(fig, use_container_width=True)
        
        with col2:
            fig = px.box(df, y=col, title=f"Box plot of {col}")
            st.plotly_chart(fig, use_container_width=True)

def export_data(df):
    st.subheader("? Export Options")
    
    col1, col2 = st.columns(2)
    
    with col1:
        csv = df.to_csv(index=False)
        st.download_button(
            label="? Download as CSV",
            data=csv,
            file_name="analyzed_data.csv",
            mime="text/csv"
        )
    
    with col2:
        json = df.to_json(orient='records')
        st.download_button(
            label="? Download as JSON",
            data=json,
            file_name="analyzed_data.json",
            mime="application/json"
        )
```

## Testing Tools

### Unit Tests

Create tests for your tool:

```python
# tests/test_my_tool.py
import pytest
from pathlib import Path
import sys

# Add tool to path
tool_path = Path(__file__).parent.parent
sys.path.append(str(tool_path))

from scripts.processor import process_data

def test_process_data():
    """Test data processing function"""
    input_data = "test input"
    result = process_data(input_data)
    
    assert result["status"] == "success"
    assert result["processed"] == "TEST INPUT"
    assert result["stats"]["length"] == 10

def test_empty_input():
    """Test with empty input"""
    with pytest.raises(ValueError):
        process_data("")
```

### Integration Tests

Test the complete tool:

```python
# tests/test_integration.py
import streamlit as st
from streamlit.testing import StreamlitTestCase

class TestMyTool(StreamlitTestCase):
    def test_render(self):
        """Test tool renders without errors"""
        from ui import render
        
        # Should not raise exceptions
        render()
        
        # Check expected elements
        assert st.title.called
        assert st.button.called
```

## Publishing Tools

### 1. Documentation

Create comprehensive documentation:

```markdown
# My Awesome Tool

## Overview
Brief description of what the tool does.

## Features
- Feature 1
- Feature 2

## Usage
Step-by-step usage instructions.

## Configuration
Any configuration options.

## Requirements
- Python 3.11+
- Additional dependencies

## Examples
Example usage with screenshots.

## Troubleshooting
Common issues and solutions.
```

### 2. Version Control

Use semantic versioning in `tool.meta.yaml`:

```yaml
version: "1.0.0"  # Major.Minor.Patch
```

### 3. Distribution

Options for sharing tools:

1. **GitHub Repository**: Share as a separate repo
2. **Pull Request**: Contribute to main MINTutil
3. **Package**: Create a pip-installable package

### 4. Tool Registry

Register your tool in the MINTutil registry (coming soon).

## Next Steps

- Check the [API Reference](api-reference.md) for available utilities
- See [Example Tools](https://github.com/data-mint-research/MINTutil/tree/main/tools) for inspiration
- Join the community to share your tools
