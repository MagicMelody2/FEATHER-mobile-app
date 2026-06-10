
# Converts Python dictionaires
import json

# Allows to be sent over UDP
import socket

# Timing control (send evyer 1 sec, sleep 2 sec)
import time

# Create random detections for testing
import random

# Creates a newwork detection sender
# UDP is used for simplicity and consistency, but TCP could be used for more reliability
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

last_hud_send = 0

# Create constants for display dimensions with margin 
WIDTH = 1920
HEIGHT = 1080
MARGIN = 50

while True:

    # Checks how long it's been since the last HUD packet was sent, and sends a new one if it's been more than 1 second
    if time.time() - last_hud_send > 1:
        with open("hud_config.json", "r") as f:
            hud_packet = json.load(f)

        # Converts Python dict to JSON string, encodes it to bytes, and sends it over UDP to the local server on port 4242
        sock.sendto(
            json.dumps(hud_packet).encode(),
            ("127.0.0.1", 4242)
        )

        # Updates the last HUD send time to the current time
        last_hud_send = time.time()

    # Generate fake detection size data for testing
    w = random.randint(int(WIDTH * 0.15), int(WIDTH * 0.35))
    h = random.randint(int(HEIGHT * 0.15), int(HEIGHT * 0.40))

    # Generate fake detection position data for testing
    x = random.randint(MARGIN, WIDTH - w - MARGIN)
    y = random.randint(MARGIN, HEIGHT - h - MARGIN)

    # Simulates fake detection data based on JSON and random values for testing, with a common label, scientific label, confidence score, and bounding box coordinates
    detection = {
        "commonlabel": "Blue Jay",
        "scientificlabel": "Cyanocitta Cristata",
        "confidencelabel": round(random.uniform(0.2, 0.99), 2),
        "x": x,
        "y": y,
        "w": w,
        "h": h,
    }

    # Updates the detection data with the current timestamp to simulate real-time detections
    sock.sendto(
        json.dumps(detection).encode(),
        ("127.0.0.1", 4242)
    )

    # delay loop = 2 seconds to simulate real-time detection updates and avoid overwhelming the server with too many packets 
    time.sleep(2)