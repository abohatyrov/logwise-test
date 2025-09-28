# Stage 1: The Builder
# This stage installs dependencies into a virtual environment.
FROM python:3.11-slim-bullseye AS builder

WORKDIR /app

# Install poetry for dependency management (best practice)
# Using poetry or similar is more robust than pip for production apps
# For this simple case, we'll stick to pip but structure it well.

# Copy only the requirements file to leverage Docker's layer caching.
# This layer is only rebuilt when requirements.txt changes.
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code
COPY . .

# Stage 2: The Final Image
# This stage creates the final, lean image for production.
FROM python:3.11-slim-bullseye

WORKDIR /app

# Copy the installed packages from the builder stage
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
# Added to include binaries like uvicorn
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy the application code from the builder stage
COPY --from=builder /app /app

# Expose the port the app runs on
EXPOSE 8000

# Command to run the application
# The --host 0.0.0.0 is critical for running in a container.
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]