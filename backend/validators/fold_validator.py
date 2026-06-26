import cv2
import numpy as np

def validate_fold_alignment(img, mode="fold_angle", baseline_width=None):
    # Preprocessing
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    blurred = cv2.GaussianBlur(gray, (5, 5), 0)
    _, thresh = cv2.threshold(blurred, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    
    contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    if not contours:
        return {
            "isValid": False,
            "score": 45,
            "status": "failed",
            "feedback": ["Tidak dapat mendeteksi objek. Pastikan latar belakang kontras dan objek terlihat jelas."],
            "details": {"error": "NO_CONTOUR_DETECTED"},
            "annotations": []
        }
        
    largest_contour = max(contours, key=cv2.contourArea)
    rect = cv2.minAreaRect(largest_contour)
    
    # Calculate normalized centroid of the largest contour
    m = cv2.moments(largest_contour)
    if m['m00'] != 0:
        cx = m['m10'] / m['m00']
        cy = m['m01'] / m['m00']
    else:
        cx, cy = rect[0]
    
    x_rel = max(0.0, min(1.0, float(cx / img.shape[1])))
    y_rel = max(0.0, min(1.0, float(cy / img.shape[0])))
    
    if mode == "strip_width":
        center, size, angle = rect
        # Warp/rotate image so that the strip is aligned upright
        M = cv2.getRotationMatrix2D(center, angle, 1.0)
        h_img, w_img = thresh.shape
        rotated_thresh = cv2.warpAffine(thresh, M, (w_img, h_img))
        
        # Recalculate contour on the rotated image
        rot_contours, _ = cv2.findContours(rotated_thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        if not rot_contours:
            return {
                "isValid": False,
                "score": 45,
                "status": "failed",
                "feedback": ["Gagal menganalisis orientasi strip. Coba luruskan sachet."],
                "details": {"error": "ROTATED_CONTOUR_FAILED"},
                "annotations": []
            }
        
        rot_largest = max(rot_contours, key=cv2.contourArea)
        rx, ry, rw, rh = cv2.boundingRect(rot_largest)
        
        # Sample widths along the long axis
        widths = []
        if rh >= rw:
            # Vertical long axis: sample horizontal rows
            for step in range(1, 10):
                y_coord = int(ry + step * (rh / 10))
                # Search within row for white pixels
                row_slice = rotated_thresh[y_coord, rx:rx+rw]
                white_px = np.where(row_slice == 255)[0]
                if len(white_px) > 1:
                    widths.append(white_px[-1] - white_px[0] + 1)
        else:
            # Horizontal long axis: sample vertical columns
            for step in range(1, 10):
                x_coord = int(rx + step * (rw / 10))
                col_slice = rotated_thresh[ry:ry+rh, x_coord]
                white_px = np.where(col_slice == 255)[0]
                if len(white_px) > 1:
                    widths.append(white_px[-1] - white_px[0] + 1)
                    
        if len(widths) < 3:
            return {
                "isValid": False,
                "score": 50,
                "status": "failed",
                "feedback": ["Lebar strip tidak dapat diukur secara konsisten. Pastikan tidak terpotong."],
                "details": {"error": "INSUFFICIENT_SAMPLES"},
                "annotations": []
            }
            
        mean_width = np.mean(widths)
        max_w = max(widths)
        min_w = min(widths)
        deviation = (max_w - min_w) / mean_width
        
        score = int(max(0, min(100, 100 - deviation * 300)))
        is_valid = score >= 70
        
        feedback = ["Lebar potongan strip sachet konsisten dan memenuhi kriteria 2-3 cm."] if is_valid else [
            "Lebar potongan strip kurang konsisten. Coba gunakan penggaris untuk memotong lebih presisi."
        ]
        
        annotations = [{
            "type": "circle" if is_valid else "warning",
            "x": x_rel,
            "y": y_rel,
            "label": "Lebar konsisten" if is_valid else "Lebar tidak konsisten"
        }]
        
        return {
            "isValid": is_valid,
            "score": score,
            "status": "good" if is_valid else "needs_improvement",
            "feedback": feedback,
            "details": {
                "measuredWidthPx": float(round(mean_width, 2)),
                "maxWidthPx": float(max_w),
                "minWidthPx": float(min_w),
                "deviation": float(round(deviation, 4))
            },
            "annotations": annotations
        }
    else: # fold_angle
        angle = rect[2]
        dev_angle = abs(angle) % 90
        if dev_angle > 45:
            dev_angle = 90 - dev_angle
            
        score = int(max(0, min(100, 100 - dev_angle * 4.0)))
        is_valid = score >= 70
        feedback = ["Lipatan strip sejajar dengan baik dan lurus."] if is_valid else [
            "Lipatan strip terdeteksi miring. Harap luruskan sejajar garis bantu kamera."
        ]
        
        annotations = [{
            "type": "circle" if is_valid else "warning",
            "x": x_rel,
            "y": y_rel,
            "label": "Lipatan sejajar" if is_valid else "Lipatan miring"
        }]
        
        return {
            "isValid": is_valid,
            "score": score,
            "status": "good" if is_valid else "needs_improvement",
            "feedback": feedback,
            "details": {"measuredAngleDeg": float(round(dev_angle, 2))},
            "annotations": annotations
        }
