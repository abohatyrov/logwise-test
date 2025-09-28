from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def read_root():
    """
    Root endpoint for the application.
    """
    return {"status": "ok", "message": "Hello from the Logwise AI DevOps Test!"}