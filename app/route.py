from fastapi import APIRouter
from app.db import table
from app.models import User

router = APIRouter()

@router.post("/user")
def create_user(user: User):
    try:
        table.put_item(Item=user.model_dump())
        return {"message": "User created"}
    except Exception as e:
        print(f"Error creating user: {e}")
        return {"error": str(e)}, 500

@router.get("/user/{user_id}")
def get_user(user_id: str):
    res = table.get_item(Key={"user_id": user_id})
    return res.get("Item", {})