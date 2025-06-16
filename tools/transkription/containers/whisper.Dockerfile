FROM python:3.10-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    ffmpeg \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install PyTorch CPU version (lighter for transcription)
RUN pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu

# Install OpenAI Whisper
RUN pip install --no-cache-dir openai-whisper

# Create directories
RUN mkdir /audio /output

# Set working directory
WORKDIR /app

# Download base model by default (can be overridden)
RUN python -c "import whisper; whisper.load_model('base')"

# Default command
CMD ["python", "-c", "print('Whisper container ready. Mount audio and output volumes.')"]