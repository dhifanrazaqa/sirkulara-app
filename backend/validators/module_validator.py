import cv2
import numpy as np

def _get_v_template_contour():
    # Draw a V-shaped polygon on a blank 200x200 canvas
    template_v = np.zeros((200, 200), dtype=np.uint8)
    v_points = np.array([
        [40, 40], [100, 160], [160, 40], 
        [130, 40], [100, 100], [70, 40]
    ], dtype=np.int32)
    cv2.fillPoly(template_v, [v_points], 255)
    contours_v, _ = cv2.findContours(template_v, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    return max(contours_v, key=cv2.contourArea)

def _get_box_template_contour():
    # Draw a square on a blank 200x200 canvas
    template_box = np.zeros((200, 200), dtype=np.uint8)
    cv2.rectangle(template_box, (45, 45), (155, 155), 255, -1)
    contours_box, _ = cv2.findContours(template_box, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    return max(contours_box, key=cv2.contourArea)

def validate_fold_module(img, shape_target="v_module"):
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
            "feedback": ["Tidak dapat mendeteksi modul. Gunakan latar belakang yang kontras."],
            "details": {"error": "NO_CONTOUR_DETECTED"},
            "annotations": []
        }
        
    largest_contour = max(contours, key=cv2.contourArea)
    
    # Calculate normalized centroid of the largest contour
    m = cv2.moments(largest_contour)
    if m['m00'] != 0:
        cx = m['m10'] / m['m00']
        cy = m['m01'] / m['m00']
    else:
        x, y, w, h = cv2.boundingRect(largest_contour)
        cx, cy = x + w / 2.0, y + h / 2.0
        
    x_rel = max(0.0, min(1.0, float(cx / img.shape[1])))
    y_rel = max(0.0, min(1.0, float(cy / img.shape[0])))
    
    if shape_target == "box_module":
        template_contour = _get_box_template_contour()
        similarity = cv2.matchShapes(largest_contour, template_contour, cv2.CONTOURS_MATCH_I1, 0.0)
        
        # Calculate polygon sides for additional sanity checks
        peri = cv2.arcLength(largest_contour, True)
        approx = cv2.approxPolyDP(largest_contour, 0.04 * peri, True)
        num_sides = len(approx)
        
        # Map shape similarity to 100-based score
        # 0.0 is perfect similarity
        score = int(max(0, min(100, 100 - similarity * 200)))
        is_valid = similarity <= 0.35 and num_sides >= 4 and num_sides <= 6
        
        feedback = ["Modul kotak terdeteksi rapi dan simetris."] if is_valid else [
            "Bentuk modul kurang presisi atau tidak kotak sempurna. Pastikan lipatan ujung saling bertemu rata."
        ]
        
        annotations = [{
            "type": "circle" if is_valid else "warning",
            "x": x_rel,
            "y": y_rel,
            "label": "Modul kotak rapi" if is_valid else "Modul tidak kotak"
        }]
        
        return {
            "isValid": is_valid,
            "score": score,
            "status": "good" if is_valid else "needs_improvement",
            "feedback": feedback,
            "details": {
                "shapeSimilarity": float(round(similarity, 4)),
                "polygonSides": num_sides
            },
            "annotations": annotations
        }
    else: # v_module
        template_contour = _get_v_template_contour()
        similarity = cv2.matchShapes(largest_contour, template_contour, cv2.CONTOURS_MATCH_I1, 0.0)
        
        # 0.0 is perfect match
        score = int(max(0, min(100, 100 - similarity * 200)))
        is_valid = similarity <= 0.35
        
        feedback = ["Bentuk modul V simetris dan rapi."] if is_valid else [
            "Bentuk modul V kurang presisi. Pastikan kedua lengan modul berukuran sama."
        ]
        
        annotations = [{
            "type": "circle" if is_valid else "warning",
            "x": x_rel,
            "y": y_rel,
            "label": "Modul V simetris" if is_valid else "Modul V kurang presisi"
        }]
        
        return {
            "isValid": is_valid,
            "score": score,
            "status": "good" if is_valid else "needs_improvement",
            "feedback": feedback,
            "details": {"shapeSimilarity": float(round(similarity, 4))} if is_valid else {"shapeSimilarity": float(round(similarity, 4))},
            "annotations": annotations
        }
