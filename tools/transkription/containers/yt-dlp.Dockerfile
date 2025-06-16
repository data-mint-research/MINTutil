FROM python:3.10-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Install yt-dlp
RUN pip install --no-cache-dir yt-dlp

# Create downloads directory
RUN mkdir /downloads

# Set working directory
WORKDIR /downloads

# Set entrypoint to yt-dlp
ENTRYPOINT ["yt-dlp"]

# Default command (can be overridden)
CMD ["--help"]