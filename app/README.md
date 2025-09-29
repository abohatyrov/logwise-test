# DevOps Test Task Starting Point

This repository contains a simple FastAPI application to be used as the starting point for the DevOps technical assessment.

## Application Details

- **`main.py`**: A minimal "Hello World" FastAPI application.
- **`requirements.txt`**: The required Python libraries.
- **`Dockerfile`**: A multi-stage Dockerfile for containerizing the application.

## How to Run Locally

To test the application on your local machine, follow these steps:

1.  **Install dependencies:**
    ```bash
    pip install -r requirements.txt
    ```

2.  **Run the server:**
    ```bash
    uvicorn main:app --reload
    ```

The application will be available at `http://127.0.0.1:8000`.
