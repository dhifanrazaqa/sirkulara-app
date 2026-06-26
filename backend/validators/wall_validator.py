import cv2
import numpy as np

def validate_weave_wall(img, side="front"):
    # Preprocessing
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    blurred = cv2.GaussianBlur(gray, (5, 5), 0)
    _, thresh = cv2.threshold(blurred, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    
    contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    if not contours:
        return {
            "isValid": False,
            "score": 40,
            "status": "failed",
            "feedback": ["Dinding tidak terdeteksi. Silakan foto ulang dari samping."],
            "details": {"error": "NO_CONTOUR_DETECTED"},
            "annotations": []
        }
        
    largest_contour = max(contours, key=cv2.contourArea)
    x, y, w, h = cv2.boundingRect(largest_contour)
    
    # Calculate wall center
    cx = x + w / 2.0
    cy = y + h / 2.0
    x_rel = max(0.0, min(1.0, float(cx / img.shape[1])))
    y_rel = max(0.0, min(1.0, float(cy / img.shape[0])))
    
    # Calculate height deviation across 9 columns of the contour
    heights = []
    # Convert largest_contour points to easily indexable numpy array
    pts = largest_contour[:, 0, :]
    
    for i in range(1, 10):
        col_x = int(x + i * (w / 10))
        # Find points near this column coordinate
        pts_in_col = pts[np.abs(pts[:, 0] - col_x) <= 3]
        if len(pts_in_col) > 0:
            y_coords = pts_in_col[:, 1]
            heights.append(max(y_coords) - min(y_coords) + 1)
            
    if len(heights) < 3:
        # Fallback to general bounding box height if sampling fails due to contour resolution
        heights = [h]
        
    mean_height = np.mean(heights)
    max_h = max(heights)
    min_h = min(heights)
    height_deviation = (max_h - min_h) / mean_height if mean_height > 0 else 0.0
    
    score = int(max(0, min(100, 100 - height_deviation * 300)))
    is_valid = score >= 70
    
    feedback = [f"Tinggi dinding sisi {side} rata dengan sisi lainnya."] if is_valid else [
        f"Ketinggian dinding sisi {side} tidak konsisten. Sesuaikan kerapatan strip."
    ]
    
    annotations = [{
        "type": "circle" if is_valid else "warning",
        "x": x_rel,
        "y": y_rel,
        "label": f"Dinding {side} rata" if is_valid else f"Dinding {side} kurang rata"
    }]
    
    return {
        "isValid": is_valid,
        "score": score,
        "status": "good" if is_valid else "needs_improvement",
        "feedback": feedback,
        "details": {
            "heightDeviationPercent": float(round(height_deviation * 100, 2)),
            "meanHeightPx": float(round(mean_height, 2)),
            "maxHeightPx": float(max_h),
            "minHeightPx": float(min_h)
        },
        "annotations": annotations
    }
