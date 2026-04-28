from fastapi import FastAPI
from app.route import router

app = FastAPI()

app.include_router(router)

#default route
@app.get("/")
def root():
    return {"message": "FastAPI + DynamoDB + uv working"}