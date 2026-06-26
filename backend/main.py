import cv2
import numpy as np
import requests
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
import logging
import traceback

from validators import (
    validate_fold_alignment,
    validate_fold_module,
    validate_weave_base,
    validate_weave_wall,
    validate_finishing,
    validate_handle
)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("validation-api")

app = FastAPI(
    title="CoMaker Vision Validation API",
    description="OpenCV-powered validation backend for upcycling crafts.",
    version="1.0.0"
)

# Helper function to download and decode image
def download_image(url: str) -> np.ndarray:
    if not url or not url.startswith("http"):
        raise ValueError("Invalid image URL")
    try:
        response = requests.get(url, timeout=8)
        if response.status_code != 200:
            raise ValueError(f"HTTP status {response.status_code}")
        image_bytes = np.frombuffer(response.content, np.uint8)
        image = cv2.imdecode(image_bytes, cv2.IMREAD_COLOR)
        if image is None:
            raise ValueError("Failed to decode image bytes")
        return image
    except Exception as e:
        logger.error(f"Error downloading image from {url}: {e}")
        raise

# Request models
class FoldAlignmentRequest(BaseModel):
    imageUrl: str
    mode: str = "fold_angle"  # strip_width, fold_angle
    baselineWidth: Optional[float] = None

class FoldModuleRequest(BaseModel):
    imageUrl: str
    shapeTarget: str = "v_module"  # v_module, box_module

class WeaveBaseRequest(BaseModel):
    imageUrl: str

class WeaveWallRequest(BaseModel):
    imageUrl: str
    side: str = "front"

class FinishingRequest(BaseModel):
    imageUrl: str

class HandleRequest(BaseModel):
    imageUrl: str
    stage: str = "construction"  # construction, attachment

class Annotation(BaseModel):
    type: str
    x: float
    y: float
    label: str

# Response model
class ValidationResponse(BaseModel):
    isValid: bool
    score: int
    status: str
    feedback: List[str]
    details: Dict[str, Any]
    annotations: Optional[List[Annotation]] = []

@app.post("/validate/fold-alignment", response_model=ValidationResponse)
def api_validate_fold_alignment(req: FoldAlignmentRequest):
    try:
        img = download_image(req.imageUrl)
        res = validate_fold_alignment(img, req.mode, req.baselineWidth)
        return ValidationResponse(**res)
    except Exception as e:
        logger.error(f"Error validating fold alignment: {traceback.format_exc()}")
        raise HTTPException(status_code=400, detail=f"Gagal memvalidasi lipatan: {str(e)}")

@app.post("/validate/fold-module", response_model=ValidationResponse)
def api_validate_fold_module(req: FoldModuleRequest):
    try:
        img = download_image(req.imageUrl)
        res = validate_fold_module(img, req.shapeTarget)
        return ValidationResponse(**res)
    except Exception as e:
        logger.error(f"Error validating fold module: {traceback.format_exc()}")
        raise HTTPException(status_code=400, detail=f"Gagal memvalidasi modul: {str(e)}")

@app.post("/validate/weave-base", response_model=ValidationResponse)
def api_validate_weave_base(req: WeaveBaseRequest):
    try:
        img = download_image(req.imageUrl)
        res = validate_weave_base(img)
        return ValidationResponse(**res)
    except Exception as e:
        logger.error(f"Error validating weave base: {traceback.format_exc()}")
        raise HTTPException(status_code=400, detail=f"Gagal memvalidasi alas: {str(e)}")

@app.post("/validate/weave-wall", response_model=ValidationResponse)
def api_validate_weave_wall(req: WeaveWallRequest):
    try:
        img = download_image(req.imageUrl)
        res = validate_weave_wall(img, req.side)
        return ValidationResponse(**res)
    except Exception as e:
        logger.error(f"Error validating weave wall: {traceback.format_exc()}")
        raise HTTPException(status_code=400, detail=f"Gagal memvalidasi dinding: {str(e)}")

@app.post("/validate/wall", response_model=ValidationResponse)
def api_validate_wall(req: WeaveWallRequest):
    return api_validate_weave_wall(req)

@app.post("/validate/finishing", response_model=ValidationResponse)
def api_validate_finishing(req: FinishingRequest):
    try:
        img = download_image(req.imageUrl)
        res = validate_finishing(img)
        return ValidationResponse(**res)
    except Exception as e:
        logger.error(f"Error validating finishing: {traceback.format_exc()}")
        raise HTTPException(status_code=400, detail=f"Gagal memvalidasi finishing: {str(e)}")

@app.post("/validate/handle", response_model=ValidationResponse)
def api_validate_handle(req: HandleRequest):
    try:
        img = download_image(req.imageUrl)
        res = validate_handle(img, req.stage)
        return ValidationResponse(**res)
    except Exception as e:
        logger.error(f"Error validating handle: {traceback.format_exc()}")
        raise HTTPException(status_code=400, detail=f"Gagal memvalidasi handle: {str(e)}")
