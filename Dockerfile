# Use Python 3.11 slim variant for a lightweight base image
FROM python:3.11-slim-bookworm AS build

# Set the working directory
WORKDIR /opt/CTFd

# Install required system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        libffi-dev \
        libssl-dev \
        git \
    && rm -rf /var/lib/apt/lists/*

# Create a virtual environment for Python dependencies
RUN python -m venv /opt/venv

# Set environment path to use virtual environment
ENV PATH="/opt/venv/bin:$PATH"

# Copy application files
COPY . /opt/CTFd

# Upgrade pip and install Python dependencies
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt && \
    for d in CTFd/plugins/*; do \
        if [ -f "$d/requirements.txt" ]; then \
            pip install --no-cache-dir -r "$d/requirements.txt"; \
        fi; \
    done;

# Release stage - final lightweight image
FROM python:3.11-slim-bookworm AS release

# Set the working directory
WORKDIR /opt/CTFd

# Install only required runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
        libffi8 \
        libssl3 \
    && rm -rf /var/lib/apt/lists/*

# Copy application files with correct ownership
COPY --chown=1001:1001 . /opt/CTFd

# Create a dedicated user for running the application
RUN useradd --no-log-init --shell /bin/bash -u 1001 ctfd && \
    mkdir -p /var/log/CTFd /var/uploads && \
    chown -R 1001:1001 /var/log/CTFd /var/uploads /opt/CTFd && \
    chmod +x /opt/CTFd/docker-entrypoint.sh

# Copy virtual environment from the build stage
COPY --chown=1001:1001 --from=build /opt/venv /opt/venv

# Set environment path
ENV PATH="/opt/venv/bin:$PATH"

# Use non-root user for better security
USER 1001

# Expose port 8000
EXPOSE 8000

# Set the entrypoint script
ENTRYPOINT ["/opt/CTFd/docker-entrypoint.sh"]
