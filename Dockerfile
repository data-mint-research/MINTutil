# MINTutil Docker Image
# Copyright (c) 2025 MINT-RESEARCH

# Multi-stage build for smaller final image
FROM python:3.11-slim as builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    gcc \
    g++ \
    git \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user for building
RUN useradd -m -u 1000 mintbuilder
USER mintbuilder
WORKDIR /home/mintbuilder/build

# Copy requirements and install Python dependencies as user
COPY --chown=mintbuilder:mintbuilder requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Final stage
FROM python:3.11-slim

# Metadata
LABEL maintainer="MINT-RESEARCH <mint-research@neomint.com>"
LABEL description="MINTutil - Modulare, intelligente Netzwerk-Tools"
LABEL version="0.1.0"

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ffmpeg \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user for runtime
RUN useradd -m -u 1000 mintuser

# Set working directory
WORKDIR /app

# Copy Python packages from builder
COPY --from=builder --chown=mintuser:mintuser /home/mintbuilder/.local /home/mintuser/.local

# Copy application code with correct ownership
COPY --chown=mintuser:mintuser . .

# Create necessary directories with proper permissions
RUN mkdir -p /app/logs /app/data /app/tools /app/scripts /app/config \
    && chown -R mintuser:mintuser /app \
    && chmod -R 755 /app

# Switch to non-root user
USER mintuser

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app:$PYTHONPATH
ENV PATH=/home/mintuser/.local/bin:$PATH
ENV STREAMLIT_SERVER_PORT=8501
ENV STREAMLIT_SERVER_ADDRESS=0.0.0.0
ENV STREAMLIT_SERVER_HEADLESS=true
ENV STREAMLIT_BROWSER_GATHER_USAGE_STATS=false

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8501/_stcore/health || exit 1

# Expose Streamlit port
EXPOSE 8501

# Run Streamlit app
CMD ["streamlit", "run", "streamlit_app/main.py", "--server.maxUploadSize", "500"]
