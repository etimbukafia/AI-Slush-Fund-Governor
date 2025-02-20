from fastapi import APIRouter, HTTPException
from fastapi.responses import JSONResponse
import logging
from validator import validate_request, extract_decision
from pydantic import BaseModel
from typing import Dict, Any

logging.basicConfig(
    format="%(asctime)s - %(levelname)s - %(message)s",
    level=logging.INFO
)

class DecisionRequest(BaseModel):
    requestData: Dict[str, Any]  # Ensure it's part of the request body

router = APIRouter()

@router.post('/decide')
async def decide(request: DecisionRequest):
    try:
        purpose = request.requestData.get("purpose")

        if not purpose:
            return JSONResponse(
                content={"error": "Missing 'purpose' field in requestData"},
                status_code=400
            )
        response = validate_request(purpose)
        logging.info(response)

        if response is None:
            return JSONResponse(
                content={"error": "Validation failed for the given purpose"},
                status_code=500
            )
        
        decision = extract_decision(response)

        return JSONResponse(content={"decision": decision}, status_code=200)
    
    except (ValueError, KeyError) as ve:
        logging.error(f"Validation Error: {str(ve)}")
        raise HTTPException(status_code=400, detail=f"Invalid Input: {str(ve)}")
    except RuntimeError as re:
        logging.error(f"Processing Error: {str(re)}")
        raise HTTPException(status_code=500, detail=f"Processing Error: {str(re)}")