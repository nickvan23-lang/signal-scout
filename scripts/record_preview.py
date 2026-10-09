#!/usr/bin/env python3
"""Record the actual DEBUG app in Simulator; sample BLE data is labeled onscreen."""
import argparse
from pathlib import Path
import signal
import subprocess
import time

p = argparse.ArgumentParser()
p.add_argument('--device', required=True)
p.add_argument('--app', type=Path, required=True)
p.add_argument('--output', type=Path, required=True)
a = p.parse_args()
a.output.mkdir(parents=True, exist_ok=True)

def sim(*args, check=True):
    return subprocess.run(['xcrun', 'simctl', *args], check=check)

sim('install', a.device, str(a.app.resolve()))
sim('status_bar', a.device, 'override', '--time', '9:41', '--dataNetwork', 'wifi', '--wifiMode', 'active', '--wifiBars', '3', '--batteryState', 'charged', '--batteryLevel', '100')
sim('terminate', a.device, 'com.nicholasvandervelden.SignalScout', check=False)
sim('launch', a.device, 'com.nicholasvandervelden.SignalScout', '-SignalScoutScreenshotMode', '-SignalScoutVideoMode')
raw = a.output / 'simulator-original.mov'
with (a.output / 'recording.log').open('w') as log:
    capture = subprocess.Popen(['xcrun', 'simctl', 'io', a.device, 'recordVideo', '--codec=h264', str(raw)], stdout=log, stderr=log)
    try:
        time.sleep(27)
    finally:
        capture.send_signal(signal.SIGINT)
        capture.wait(timeout=30)
subprocess.run(['ffmpeg', '-y', '-i', str(raw), '-f', 'lavfi', '-i', 'anullsrc=channel_layout=stereo:sample_rate=48000', '-t', '26', '-vf', 'scale=886:1920:flags=lanczos,setsar=1', '-r', '30', '-c:v', 'libx264', '-profile:v', 'high', '-level:v', '4.0', '-b:v', '10M', '-maxrate', '12M', '-bufsize', '20M', '-pix_fmt', 'yuv420p', '-c:a', 'aac', '-b:a', '256k', '-movflags', '+faststart', str(a.output / 'SignalScout-AppPreview-886x1920.mp4')], check=True)
print('Recorded real app UI with simulated BLE input; this is not a physical-device recording.')
