from datetime import datetime
import base64

import cv2
import numpy as np
import uvicorn
from fastapi import FastAPI, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware

from fracture_pipeline import FracturePipeline


CLS_MODEL_PATH = r"weights/effnet_best.pt"
YOLO_MODEL_PATH = r"weights/yolo_best.pt"

pipeline = FracturePipeline(
    cls_model_path=CLS_MODEL_PATH,
    yolo_model_path=YOLO_MODEL_PATH,
    model_name="tf_efficientnet_b2",
    img_size=320,
    cls_threshold_run_det=0.40,
    cls_threshold_suspect=0.60,
    det_conf=0.15,
    det_iou=0.45,
)

history = []

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
async def health():
    return {"status": "ok"}


@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    img_bytes = await file.read()
    nparr = np.frombuffer(img_bytes, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

    if img is None:
        return {"error": "Could not decode image"}

    h, w = img.shape[:2]

    result = pipeline.predict_bgr(img)
    annotated = result.pop("annotated_image_bgr")

    ok, buffer = cv2.imencode(".png", annotated)
    if not ok:
        return {"error": "Failed to encode annotated image"}

    img_b64 = base64.b64encode(buffer.tobytes()).decode("utf-8")

    response = {
        "has_fracture": result["has_fracture"],
        "best_confidence": result["max_box_conf"],
        "num_boxes": result["num_boxes"],
        "boxes": result["boxes"],
        "annotated_image_b64": img_b64,
        "width": w,
        "height": h,
        "timestamp": datetime.now().isoformat(),

        "p_fracture": result["p_fracture"],
        "cls_pred_0_1": result["cls_pred_0_1"],
        "ran_detector": result["ran_detector"],
        "max_box_conf": result["max_box_conf"],
        "final_decision": result["final_decision"],
        "final_pred_0_1": result["final_pred_0_1"],
    }

    history.append(response)
    return response


@app.get("/history")
async def get_history():
    return {"history": list(reversed(history))}


if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8000)