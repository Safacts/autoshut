# idle_server.py
from flask import Flask, jsonify, request
import ctypes
import os
import threading
import time

app = Flask(__name__)
idle_limit = 30  # Default idle limit in seconds (can be modified by Flutter app)

def get_idle_duration():
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
    while True:
        idle_time = get_idle_duration()
        if idle_time >= idle_limit:
            print("Idle time limit exceeded. Shutting down...")
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
        idle_limit = data['limit']
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
    app.run(port=5000)


@app.route('/reset_idle_time', methods=['POST'])
def reset_idle_time():
    """Resets the idle time on server side."""
    global idle_start_time  # Assuming you use idle_start_time to calculate idle duration
    idle_start_time = time.time()  # Reset the idle start to the current time
    return jsonify({"status": "Idle time reset"})
