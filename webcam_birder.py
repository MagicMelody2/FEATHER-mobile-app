#(.venv) C:\Users\grace\OneDrive\Desktop\florida-bird-classifier-mainC:\Users\grace\.venv\Scripts\python.exe webcam_birder.py

DEVICE_ID = "FEATHER-000"

from supabase import create_client
url = "https://llddhtatznrbrhxoniqc.supabase.co"
key = "sb_publishable_48nEIOwcY4KGdg4ClqIC-w_VGsKOXLZ"

supabase = create_client(url, key)


import cv2
import birder
from birder.inference.classification import infer_image
from PIL import Image

import socket
import json
UDP_IP = "127.0.0.1"
UDP_PORT = 4242

import time

from collections import deque
history = deque(maxlen=10)

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

# -----------------------
# load bird database from supabase
# -----------------------
def get_bird_info(bird_key):
    print("LOOKUP KEY:", repr(bird_key))

    response = supabase.table("taxonomy") \
        .select("*") \
        .eq("key", bird_key) \
        .execute()

    data = response.data
    print("RAW RESPONSE:", data)

    if not data:
        return {
            "common_name": bird_key,
            "scientific_name": "Unknown",
            "conservation_status": "Unknown"
        }

    return data[0]

# -----------------------
# load device ids database from supabase
# -----------------------

def get_user_from_device(device_serial):
    response = (
        supabase.table("device_codes")
        .select("user_id")
        .eq("device_serial", device_serial)
        .single()
        .execute()
    )

    print("DEVICE LOOKUP:", response)

    if not response.data:
        print("No user mapped to device!")
        return None

    return response.data["user_id"]

# -----------------------
# load hud settings database from supabase
# -----------------------

def get_hud_settings(user_id):
    print(f"Looking up HUD settings for user: {user_id}")

    response = (
        supabase.table("user_hud_settings")
        .select("settings, hud_version")
        .eq("user_id", user_id)
        .maybe_single()
        .execute()
    )

    print("Response data:", response.data)

    if not response.data:
        print("No HUD settings found.")
        return None

    return {
        "settings": response.data["settings"],
        "hud_version": response.data["hud_version"]
    }

# -----------------------
# Load model
# -----------------------
model_name = "mobilenet_v4_s_il-common"

(net, model_info) = birder.load_pretrained_model(
    model_name,
    inference=True
)

size = birder.get_size_from_signature(model_info.signature)
transform = birder.classification_transform(size, model_info.rgb_stats)

idx_to_class = {v: k for k, v in model_info.class_to_idx.items()}

# -----------------------
# Open webcam
# -----------------------
cap = cv2.VideoCapture(0)

if not cap.isOpened():
    print("Could not open webcam.")
    exit()

frame_count = 0

last_bird = "Searching..."
last_confidence = 0.0
info = {}

last_hud_version = -1

user_id = get_user_from_device(DEVICE_ID)

if user_id is None:
    print("No user assigned to device. Exiting.")
    exit()


hud = get_hud_settings(user_id)
last_hud_version = hud["hud_version"]
hud_settings = hud["settings"]

if hud is None:
    hud = {
        "settings": {
            "hud_color": "#FFFFFF",
            "hud_layout": "layout1",
            "hud_fields": ["Common Name", "Scientific Name", "Confidence", None]
        },
        "hud_version": 0
    }
print("HUD LOADED:", hud)

while True:
    ret, frame = cap.read()
    if not ret:
        break

    display = frame.copy()

    frame_count += 1

    if frame_count % 10 == 0:

        # -----------------------
        # RUN MODEL
        # -----------------------
        rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        image = Image.fromarray(rgb)

        (out, _) = infer_image(net, image, transform)

        probs = out[0]
        best = probs.argmax()

        bird = idx_to_class.get(best)
        if not bird:
            continue
        confidence = float(probs[best])
        
        # -----------------------
        # SMOOTHING (no flicker)
        # -----------------------
        history.append((bird, confidence))

        counts = {}
        conf_sum = {}

        for b, c in history:
            counts[b] = counts.get(b, 0) + 1
            conf_sum[b] = conf_sum.get(b, 0) + c

        stable_bird = max(counts, key=counts.get)
        stable_conf = conf_sum[stable_bird]/counts[stable_bird] 

        bird_key = stable_bird.replace(" ", "_")
        print("LOOKUP KEY:", bird_key)

        last_bird = stable_bird
        last_confidence = stable_conf

        # -----------------------
        # SUPABASE LOOKUP 
        # -----------------------
        info = get_bird_info(bird_key)

        if "settings" not in hud:
            print("HUD ERROR: missing settings block")
            continue
        
        payload = {
            "type": "detection",
            "x": 200,
            "y": 150,
            "w": 220,
            "h": 220,
            "common_name": info["common_name"],
            "scientific_name": info["scientific_name"],
            "conservation_status": info["conservation_status"],
            "confidence": stable_conf,

            "hud_color": hud["settings"]["hud_color"],
            "hud_layout": hud["settings"]["hud_layout"],
            "hud_fields": hud["settings"]["hud_fields"]
        }

        sock.sendto(
            json.dumps(payload).encode("utf-8"),
            (UDP_IP, UDP_PORT)
        )

        print("SENDING UDP:", payload)

        # -----------------------
        # CHECK IF HUD UPDATED
        # -----------------------
        hud_check = get_hud_settings(user_id)

        if hud_check["hud_version"] != last_hud_version:
            print("HUD UPDATED")

            last_hud_version = hud_check["hud_version"]

            hud = hud_check

        last_hud_version = hud_check["hud_version"]
        hud_settings = hud_check["settings"]

    # -----------------------
    # LOCAL DISPLAY
    # -----------------------

    cv2.putText(display,
        f"{info.get('common_name', last_bird)}",
        (20, 40),
        cv2.FONT_HERSHEY_SIMPLEX,
        1,
        (0, 255, 0),
        2,
    )

    cv2.putText(display,
        f"Scientific: {info.get('scientific_name', 'Unknown')}",
        (20, 80),
        cv2.FONT_HERSHEY_SIMPLEX,
        0.7,
        (255, 255, 255),
        2,
    )

    cv2.putText(display,
        f"Status: {info.get('conservation_status', 'Unknown')}",
        (20, 120),
        cv2.FONT_HERSHEY_SIMPLEX,
        0.7,
        (0, 200, 255),
        2,
    )

    cv2.putText(display,
        f"Confidence: {last_confidence:.2f}",
        (20, 160),
        cv2.FONT_HERSHEY_SIMPLEX,
        0.7,
        (0, 255, 0),
        2,
    )

    cv2.imshow("Birder Webcam", display)

    if cv2.waitKey(1) == ord("q"):
        break

cap.release()
cv2.destroyAllWindows()