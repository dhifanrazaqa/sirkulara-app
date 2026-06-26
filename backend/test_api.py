import requests
import json

base_url = "http://localhost:8000"

def test_endpoint(endpoint, payload):
    url = f"{base_url}{endpoint}"
    print(f"POST {url} with {json.dumps(payload)}")
    try:
        response = requests.post(url, json=payload)
        print(f"Status Code: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
    except Exception as e:
        print(f"Error testing {endpoint}: {e}")
    print("-" * 50)

if __name__ == "__main__":
    # Test with standard URLs (e.g. ideal images or simple mockup targets)
    mock_url = "https://images.unsplash.com/photo-1611080626919-7cf5a9dbab5b"
    
    test_endpoint("/validate/fold-alignment", {
        "imageUrl": mock_url,
        "mode": "strip_width"
    })
    test_endpoint("/validate/fold-alignment", {
        "imageUrl": mock_url,
        "mode": "fold_angle"
    })
    test_endpoint("/validate/fold-module", {
        "imageUrl": mock_url,
        "shapeTarget": "v_module"
    })
    test_endpoint("/validate/weave-base", {
        "imageUrl": mock_url
    })
    test_endpoint("/validate/weave-wall", {
        "imageUrl": mock_url,
        "side": "front"
    })
    test_endpoint("/validate/wall", {
        "imageUrl": mock_url,
        "side": "front"
    })
    test_endpoint("/validate/finishing", {
        "imageUrl": mock_url
    })
    test_endpoint("/validate/handle", {
        "imageUrl": mock_url,
        "stage": "construction"
    })
