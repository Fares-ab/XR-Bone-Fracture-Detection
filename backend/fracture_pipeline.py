from typing import Optional, Dict, Any, List

import cv2
import numpy as np
import torch
import timm
from PIL import Image
from torchvision import transforms
from ultralytics import YOLO


class FracturePipeline:
    def __init__(
        self,
        cls_model_path: str,
        yolo_model_path: str,
        model_name: str = "tf_efficientnet_b2",
        img_size: int = 320,
        device: Optional[str] = None,
        cls_threshold_run_det: float = 0.40,
        cls_threshold_suspect: float = 0.60,
        det_conf: float = 0.15,
        det_iou: float = 0.45,
    ):
        self.cls_model_path = cls_model_path
        self.yolo_model_path = yolo_model_path
        self.model_name = model_name
        self.img_size = img_size
        self.device = device or ("cuda" if torch.cuda.is_available() else "cpu")

        self.cls_threshold_run_det = cls_threshold_run_det
        self.cls_threshold_suspect = cls_threshold_suspect
        self.det_conf = det_conf
        self.det_iou = det_iou

        self.transform = transforms.Compose([
            transforms.Grayscale(num_output_channels=3),
            transforms.Resize(int(self.img_size * 1.14)),
            transforms.CenterCrop(self.img_size),
            transforms.ToTensor(),
            transforms.Normalize(
                mean=[0.485, 0.456, 0.406],
                std=[0.229, 0.224, 0.225],
            ),
        ])

        self.cls_model, self.fracture_idx, self.num_classes = self._load_classifier(self.cls_model_path)
        self.det_model = YOLO(self.yolo_model_path)

    def _load_classifier(self, model_path: str):
        checkpoint = torch.load(model_path, map_location=self.device)

        if isinstance(checkpoint, dict):
            ckpt_model_name = checkpoint.get("model_name", self.model_name)
            class_to_idx = checkpoint.get("class_to_idx", None)
            fracture_idx = checkpoint.get("fracture_idx", None)

            if "state_dict" in checkpoint:
                state_dict = checkpoint["state_dict"]
            elif "model_state_dict" in checkpoint:
                state_dict = checkpoint["model_state_dict"]
            else:
                state_dict = checkpoint
        else:
            ckpt_model_name = self.model_name
            class_to_idx = None
            fracture_idx = None
            state_dict = checkpoint

        if "classifier.weight" in state_dict:
            num_classes = state_dict["classifier.weight"].shape[0]
        else:
            num_classes = 2

        model = timm.create_model(
            ckpt_model_name,
            pretrained=False,
            num_classes=num_classes,
        )

        cleaned_state_dict = {}
        for k, v in state_dict.items():
            new_key = k.replace("module.", "") if k.startswith("module.") else k
            cleaned_state_dict[new_key] = v

        model.load_state_dict(cleaned_state_dict, strict=True)
        model.to(self.device)
        model.eval()

        if fracture_idx is None:
            if class_to_idx is not None and "fracture" in class_to_idx:
                fracture_idx = class_to_idx["fracture"]
            else:
                fracture_idx = 1

        return model, fracture_idx, num_classes

    @torch.no_grad()
    def _predict_classifier_from_bgr(self, image_bgr: np.ndarray):
        image_rgb = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2RGB)
        pil_img = Image.fromarray(image_rgb)

        x = self.transform(pil_img).unsqueeze(0).to(self.device)
        logits = self.cls_model(x)

        if self.num_classes == 1:
            prob_fracture = torch.sigmoid(logits).item()
            pred_label = 1 if prob_fracture >= 0.5 else 0
        else:
            probs = torch.softmax(logits, dim=1)[0]
            prob_fracture = probs[self.fracture_idx].item()
            pred_label = int(torch.argmax(probs).item() == self.fracture_idx)

        return float(prob_fracture), int(pred_label)

    def _run_detector(self, image_bgr: np.ndarray) -> List[Dict[str, Any]]:
        results = self.det_model.predict(
            source=image_bgr,
            conf=self.det_conf,
            iou=self.det_iou,
            verbose=False,
            save=False,
        )

        result = results[0]
        boxes_out = []

        if result.boxes is not None and len(result.boxes) > 0:
            xyxy = result.boxes.xyxy.cpu().numpy()
            confs = result.boxes.conf.cpu().numpy()
            class_ids = result.boxes.cls.cpu().numpy()

            for box, conf, cls_id in zip(xyxy, confs, class_ids):
                x1, y1, x2, y2 = box.astype(int).tolist()
                boxes_out.append({
                    "x1": x1,
                    "y1": y1,
                    "x2": x2,
                    "y2": y2,
                    "conf": float(conf),
                    "class_id": int(cls_id),
                })

        return boxes_out

    def _get_final_decision(self, p_fracture: float, boxes: List[Dict[str, Any]]) -> str:
        if p_fracture < self.cls_threshold_run_det:
            return "fracture unlikely"

        if len(boxes) > 0:
            return "fracture likely - localization found"

        if p_fracture >= self.cls_threshold_suspect:
            return "fracture suspected - localization not found"

        return "fracture unlikely"




    @staticmethod
    def _draw_label_box(img, text, x, y, font_scale=None, thickness=None):
        h, w = img.shape[:2]
        base = max(400, min(h, w))

        if font_scale is None:
            font_scale = max(0.45, min(0.8, base / 900.0))
        if thickness is None:
            thickness = max(1, int(base / 420))

        pad = max(4, int(base / 220))
        font = cv2.FONT_HERSHEY_SIMPLEX
        (tw, th), baseline = cv2.getTextSize(text, font, font_scale, thickness)

        bg_x1 = max(5, x)
        bg_y2 = y - 6
        bg_y1 = bg_y2 - th - 2 * pad
        bg_x2 = bg_x1 + tw + 2 * pad

        if bg_y1 < 5:
            bg_y1 = max(5, y + 4)
            bg_y2 = bg_y1 + th + 2 * pad

        if bg_x2 > w - 5:
            shift = bg_x2 - (w - 5)
            bg_x1 -= shift
            bg_x2 -= shift

        cv2.rectangle(img, (bg_x1, bg_y1), (bg_x2, bg_y2), (0, 0, 0), -1)
        cv2.putText(
            img,
            text,
            (bg_x1 + pad, bg_y2 - pad),
            font,
            font_scale,
            (255, 255, 255),
            thickness,
            cv2.LINE_AA,
        )

    def _annotate_image(
        self,
        image_bgr: np.ndarray,
        boxes: List[Dict[str, Any]],
        p_fracture: float,
        final_decision: str,
    ) -> np.ndarray:
        img = image_bgr.copy()

        h, w = img.shape[:2]
        box_thickness = max(2, int(min(h, w) / 300))

        for i, b in enumerate(boxes, start=1):
            x1, y1, x2, y2 = b["x1"], b["y1"], b["x2"], b["y2"]
            conf = b["conf"]

            cv2.rectangle(img, (x1, y1), (x2, y2), (0, 255, 0), box_thickness)
            self._draw_label_box(img, f"fracture_box {i}: {conf:.2f}", x1, y1)

        return img

    def predict_bgr(self, image_bgr: np.ndarray) -> Dict[str, Any]:
        p_fracture, cls_pred = self._predict_classifier_from_bgr(image_bgr)

        boxes = []
        ran_detector = False

        if p_fracture >= self.cls_threshold_run_det:
            ran_detector = True
            boxes = self._run_detector(image_bgr)

        final_decision = self._get_final_decision(p_fracture, boxes)
        final_pred_0_1 = 1 if final_decision != "fracture unlikely" else 0

        annotated = self._annotate_image(
            image_bgr=image_bgr,
            boxes=boxes,
            p_fracture=p_fracture,
            final_decision=final_decision,
        )

        return {
            "p_fracture": float(p_fracture),
            "cls_pred_0_1": int(cls_pred),
            "ran_detector": int(ran_detector),
            "num_boxes": len(boxes),
            "max_box_conf": max([b["conf"] for b in boxes], default=0.0),
            "boxes": boxes,
            "final_decision": final_decision,
            "final_pred_0_1": int(final_pred_0_1),
            "has_fracture": bool(final_pred_0_1),
            "annotated_image_bgr": annotated,
        }