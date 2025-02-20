from fastapi import FastAPI
import uvicorn
from fastapi.middleware.cors import CORSMiddleware
import os
from routes.decisionRoute import router as decision_router

PORT = int(os.getenv("PORT", 8000))

app = FastAPI()
    
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Replace with specific origins in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(decision_router)

if __name__ == "__main__":
   uvicorn.run("server:app", host="0.0.0.0", port=PORT, log_level="info", reload=True)