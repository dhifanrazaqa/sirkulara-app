import cv2
import numpy as np

def validate_handle(img, stage="construction"):
    # Preprocessing
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    blurred = cv2.GaussianBlur(gray, (5, 5), 0)
    _, thresh = cv2.threshold(blurred, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    
    contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    
    # Filter and sort contours by area to find candidates for handles
    handle_candidates = []
    for c in contours:
        area = cv2.contourArea(c)
        if area > 100: # filter out tiny noise contours
            rect = cv2.minAreaRect(c)
            width, height = rect[1]
            if width > 0 and height > 0:
                aspect_ratio = max(width, height) / min(width, height)
                # Handles are elongated shapes, aspect ratio should be significant
                if aspect_ratio >= 1.5:
                    handle_candidates.append(c)
                    
    handle_candidates = sorted(handle_candidates, key=cv2.contourArea, reverse=True)
    
    if len(handle_candidates) < 2:
        return {
            "isValid": False,
            "score": 45,
            "status": "failed",
            "feedback": ["Tidak dapat mendeteksi kedua handle secara terpisah. Pastikan background kontras dan kedua handle berjarak."],
            "details": {"error": "INSUFFICIENT_HANDLES_DETECTED", "candidatesFound": len(handle_candidates)},
            "annotations": []
        }
        
    c1, c2 = handle_candidates[0], handle_candidates[1]
    
    # Calculate centroids
    m1 = cv2.moments(c1)
    m2 = cv2.moments(c2)
    if m1['m00'] != 0:
        cx1, cy1 = m1['m10']/m1['m00'], m1['m01']/m1['m00']
    else:
        r1 = cv2.minAreaRect(c1)
        cx1, cy1 = r1[0]
        
    if m2['m00'] != 0:
        cx2, cy2 = m2['m10']/m2['m00'], m2['m01']/m2['m00']
    else:
        r2 = cv2.minAreaRect(c2)
        cx2, cy2 = r2[0]
        
    x1_rel = max(0.0, min(1.0, float(cx1 / img.shape[1])))
    y1_rel = max(0.0, min(1.0, float(cy1 / img.shape[0])))
    x2_rel = max(0.0, min(1.0, float(cx2 / img.shape[1])))
    y2_rel = max(0.0, min(1.0, float(cy2 / img.shape[0])))
    
    if stage == "construction":
        # Compare length of both handle strips
        len1 = cv2.arcLength(c1, True)
        len2 = cv2.arcLength(c2, True)
        
        max_len = max(len1, len2)
        deviation = abs(len1 - len2) / max_len if max_len > 0 else 0.0
        
        score = int(max(0, min(100, 100 - deviation * 300)))
        is_valid = score >= 70
        
        feedback = ["Panjang kedua pegangan simetris dan anyamannya rapat."] if is_valid else [
            "Panjang handle kiri dan kanan kurang rata. Samakan jumlah modul anyamannya."
        ]
        
        annotations = [
            {
                "type": "circle" if is_valid else "warning",
                "x": x1_rel,
                "y": y1_rel,
                "label": "Pegangan kiri/kanan" if is_valid else "Pegangan tidak sama panjang"
            },
            {
                "type": "circle" if is_valid else "warning",
                "x": x2_rel,
                "y": y2_rel,
                "label": "Pegangan kiri/kanan" if is_valid else "Pegangan tidak sama panjang"
            }
        ]
        
        return {
            "isValid": is_valid,
            "score": score,
            "status": "good" if is_valid else "needs_improvement",
            "feedback": feedback,
            "details": {
                "lengthDeviationPercent": float(round(deviation * 100, 2)),
                "length1Px": float(round(len1, 2)),
                "length2Px": float(round(len2, 2))
            },
            "annotations": annotations
        }
    else: # stage == "attachment" (symmetry check against image vertical center axis)
        img_w = img.shape[1]
        img_center_x = img_w / 2.0
        
        # Calculate centroids of both handles using moments
        m1 = cv2.moments(c1)
        m2 = cv2.moments(c2)
        
        if m1['m00'] == 0 or m2['m00'] == 0:
            return {
                "isValid": False,
                "score": 50,
                "status": "failed",
                "feedback": ["Gagal menghitung titik tengah handle. Silakan ambil foto ulang dengan pencahayaan merata."],
                "details": {"error": "ZERO_MOMENTS"},
                "annotations": []
            }
            
        cx1 = m1['m10'] / m1['m00']
        cx2 = m2['m10'] / m2['m00']
        
        # Distance of each handle's centroid to center axis
        dist1 = abs(cx1 - img_center_x)
        dist2 = abs(cx2 - img_center_x)
        
        max_dist = max(dist1, dist2)
        deviation = abs(dist1 - dist2) / max_dist if max_dist > 0 else 0.0
        
        score = int(max(0, min(100, 100 - deviation * 300)))
        is_valid = score >= 70
        
        feedback = ["Pegangan terpasang simetris dari garis tengah tas."] if is_valid else [
            "Posisi handle miring atau tidak simetris. Ukur jarak penempelan handle kembali."
        ]
        
        annotations = [
            {
                "type": "circle" if is_valid else "warning",
                "x": x1_rel,
                "y": y1_rel,
                "label": f"Jarak: {int(dist1)}px"
            },
            {
                "type": "circle" if is_valid else "warning",
                "x": x2_rel,
                "y": y2_rel,
                "label": f"Jarak: {int(dist2)}px"
            }
        ]
        
        return {
            "isValid": is_valid,
            "score": score,
            "status": "good" if is_valid else "needs_improvement",
            "feedback": feedback,
            "details": {
                "symmetryDeviationPercent": float(round(deviation * 100, 2)),
                "distanceLeftPx": float(round(dist1, 2)),
                "distanceRightPx": float(round(dist2, 2))
            },
            "annotations": annotations
        }
