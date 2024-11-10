from flask import Flask, jsonify, request
import ctypes
import os
import threading
import time
import logging
from waitress import serve

# Configure logging
logging.basicConfig(level=logging.INFO)

app = Flask(__name__)

# Global variable for idle limit, initialized as None
idle_limit = None
idle_limit_lock = threading.Lock()  # Lock for thread-safe updates to idle_limit

def get_idle_duration():
    """Get the current system idle time in seconds."""
    class LASTINPUTINFO(ctypes.Structure):
        _fields_ = [('cbSize', ctypes.c_uint), ('dwTime', ctypes.c_uint)]
    lii = LASTINPUTINFO()
    lii.cbSize = ctypes.sizeof(LASTINPUTINFO)
    if ctypes.windll.user32.GetLastInputInfo(ctypes.byref(lii)):
        millis_idle = ctypes.windll.kernel32.GetTickCount() - lii.dwTime
        return millis_idle / 1000.0  # Convert to seconds
    else:
        return 0

def monitor_inactivity():
    """Monitor idle time and trigger shutdown if it exceeds the idle limit."""
    global idle_limit
    
    # Wait until the idle_limit is set by the app
    while True:
        with idle_limit_lock:
            if idle_limit is not None:
                break
        logging.info("Waiting for idle limit to be set by the app...")
        time.sleep(1)
    
    logging.info(f"Monitoring started with initial idle limit: {idle_limit} seconds")

    while True:
        idle_time = get_idle_duration()

        # Access idle_limit in a thread-safe way
        with idle_limit_lock:
            current_limit = idle_limit

        if current_limit is not None and idle_time >= current_limit:
            logging.info("Idle time limit exceeded. Shutting down...")
            os.system("shutdown /s /t 0")  # Immediate shutdown command
            break
        time.sleep(1)

@app.route('/idle_time', methods=['GET'])
def idle_time():
    """Returns the current idle time in seconds."""
    idle_duration = get_idle_duration()
    return jsonify({"idle_time": int(idle_duration)})

@app.route('/set_idle_limit', methods=['POST'])
def set_idle_limit():
    """Sets a new idle time limit for shutdown."""
    global idle_limit
    data = request.json
    if 'limit' in data:
        with idle_limit_lock:
            idle_limit = data['limit']
        logging.info(f"Idle limit updated to {idle_limit} seconds")
        return jsonify({"status": "Idle limit updated", "new_limit": idle_limit})
    return jsonify({"status": "Failed", "message": "Invalid data"}), 400

@app.route('/shutdown', methods=['POST'])
def shutdown():
    """Manually trigger system shutdown."""
    os.system("shutdown /s /t 0")
    return jsonify({"status": "System shutting down..."})

if __name__ == '__main__':
    # Start inactivity monitor in a separate thread
    threading.Thread(target=monitor_inactivity, daemon=True).start()
    # Use waitress to serve the app instead of app.run() for production use
    serve(app, host='127.0.0.1', port=5000)
