# XR-Bone-Fracture-Detection

XR-Bone is an AI-powered Windows desktop application for X-ray bone fracture detection.

The system uses a two-stage deep learning pipeline:

1. **EfficientNet-B2 classifier** for whole-image fracture / no-fracture prediction.
2. **YOLOv8s detector** for fracture localization using bounding boxes.

The project also includes a Flutter desktop frontend, a FastAPI backend, local report history, and annotated X-ray visualization.

---

## My Role

I contributed to the data and database side of the XR-Bone project. My work focused on organizing bone-related data and supporting the data flow needed for displaying accurate information within the application.

## My Contributions

- Designed bone-related data structures.
- Organized project data for content display.
- Supported database storage and data retrieval.
- Assisted in testing, documentation, and final project delivery.

---

## Project Features

- X-ray image upload from a Windows desktop application
- Fracture / no-fracture classification
- Fracture localization using bounding boxes
- Annotated X-ray display
- Full-screen zoomable X-ray viewer
- Patient ID lookup
- Doctor notes
- Report saving and history page
- Light/dark theme support

---

## Final AI Pipeline

The final system uses a two-stage pipeline.

### Stage 1: Classification

The EfficientNet-B2 classifier predicts whether the uploaded X-ray is likely to contain a fracture.

Final classifier model:

```text
fracture_effnet_b2_v4_generalization
```

In the backend, this model is loaded as:

```text
backend/weights/effnet_best.pt
```

### Stage 2: Localization

If the classifier probability is high enough, the YOLO model runs to localize the fracture region.

Final detector model:

```text
fract_det_fracture_only_yolov8s_v1
```

In the backend, this model is loaded as:

```text
backend/weights/yolo_best.pt
```

---

## Backend Thresholds

Current backend thresholds:

```text
CLS_THRESHOLD_RUN_DET = 0.40
CLS_THRESHOLD_SUSPECT = 0.60
DET_CONF = 0.15
DET_IOU = 0.45
```

---

## Model Performance Summary

### Classification: EfficientNet-B2 v4

Historical accepted internal test result:

| Accuracy | F1 | AUC | TP | FP | TN | FN |
|---:|---:|---:|---:|---:|---:|---:|
| 0.9659 | 0.9628 | 0.9849 | 685 | 17 | 818 | 36 |

Current deployed `effnet_best.pt` evaluation on `cls_data_v2` test split:

| Total | Correct | Wrong | Accuracy | TP | FP | TN | FN |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 1556 | 1505 | 51 | 0.9672 | 685 | 15 | 820 | 36 |

External Dataset 5 raw evaluation:

| Total | Correct | Wrong | Accuracy | TP | FP | TN | FN |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 294 | 164 | 130 | 0.5578 | 78 | 117 | 86 | 13 |

Best Dataset 5 threshold-sweep result at threshold 0.95:

| Accuracy | TP | FP | TN | FN |
|---:|---:|---:|---:|---:|
| 0.6633 | 70 | 78 | 125 | 21 |

### Classification Train / Validation / Test Evaluation

| Split | Total | Correct | Wrong | Accuracy | TP | FP | TN | FN |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Train | 15394 | 15382 | 12 | 0.9992 | 7536 | 5 | 7846 | 7 |
| Validation | 2126 | 2052 | 74 | 0.9652 | 877 | 16 | 1175 | 58 |
| Test | 1556 | 1505 | 51 | 0.9672 | 685 | 15 | 820 | 36 |

### Localization: YOLO

| Model | Precision | Recall | mAP50 | mAP50-95 |
|---|---:|---:|---:|---:|
| `fract_det_recall` | 0.703 | 0.545 | 0.560 | 0.265 |
| `fract_det_v2_ft_clean` | 0.622 | 0.520 | 0.547 | 0.237 |
| `fract_det_fracture_only_yolov8s_v1` | 0.713 | 0.572 | 0.622 | 0.270 |

Current deployed `yolo_best.pt` evaluation on `yolo_data_fracture_only` test split:

| Images | Images with Any Match | Strict Image Correct | TP Boxes | FP Boxes | FN Boxes | Precision | Recall |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 183 | 119 | 81 | 132 | 100 | 94 | 0.5690 | 0.5841 |

---

## Dataset Summary

Datasets are not included in this repository due to size and licensing.

### Classification Dataset: `cls_data_v2`

Final current distribution after corrupted-image cleanup:

| Split | Fracture | No Fracture | Total |
|---|---:|---:|---:|
| Train | 7543 | 7851 | 15394 |
| Validation | 935 | 1191 | 2126 |
| Test | 721 | 835 | 1556 |
| Total | 9199 | 9877 | 19076 |

### Localization Dataset: `yolo_data_fracture_only`

Final fracture-only localization dataset:

| Split | Fracture Images | No Fracture Images | Total |
|---|---:|---:|---:|
| Train | 1537 | 0 | 1537 |
| Validation | 298 | 0 | 298 |
| Test | 183 | 0 | 183 |
| Total | 2018 | 0 | 2018 |

---

## Project Structure

```text
xrbonemain/
  backend/
    main.py
    fracture_pipeline.py
    requirements.txt
    weights/
      effnet_best.pt
      yolo_best.pt

  frontend/
    lib/
      main.dart
      db_helper.dart
      screens/
      theme/
    pubspec.yaml

  README.md
  dataset_info.txt
  requirements.txt
```

---

## Backend Setup

Go to the backend folder:

```powershell
cd backend
```

Install dependencies:

```powershell
pip install -r requirements.txt
```

Run the backend:

```powershell
python main.py
```

The backend runs on:

```text
http://127.0.0.1:8000
```

Health check:

```text
http://127.0.0.1:8000/health
```

---

## Frontend Setup

Go to the frontend folder:

```powershell
cd frontend
```

Install Flutter dependencies:

```powershell
flutter pub get
```

Run the Windows desktop app:

```powershell
flutter run -d windows
```

---

## Model Weights

This repository is intended to include model weights using Git LFS:

```text
backend/weights/effnet_best.pt
backend/weights/yolo_best.pt
```

If the model files are missing after cloning, make sure Git LFS is installed:

```powershell
git lfs install
git lfs pull
```

---

## Git LFS

This repository uses Git LFS for model files:

```text
*.pt
*.pth
*.onnx
```

Before pushing model weights, run:

```powershell
git lfs install
git lfs track "*.pt"
git lfs track "*.pth"
git lfs track "*.onnx"
```

---

## Important Note

This project is for academic and research purposes only. It is not a replacement for professional medical diagnosis by qualified healthcare specialists.

Model weight files are not included in this repository due to size limitations.

