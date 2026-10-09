#!/usr/bin/env python3
import json,os,subprocess,time
from pathlib import Path
root=Path('evidence');app=Path(os.environ['RUNNER_TEMP'])/'ScoutDerivedData/Build/Products/Debug-iphonesimulator/SignalScout.app'
runtime=json.loads((root/'simulator.json').read_text())['runtime'];primary=os.environ['SCOUT_SIM'];bundle='com.nicholasvandervelden.SignalScout'
def run(*args,check=True):
 return subprocess.run(['xcrun','simctl',*args],check=check,capture_output=True,text=True,timeout=120)
for label,device_type in [('large',None),('medium','com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro'),('face-id-large','com.apple.CoreSimulator.SimDeviceType.iPhone-13-Pro-Max')]:
 device=primary if device_type is None else run('create','SignalScout '+label,device_type,runtime).stdout.strip()
 try:
  run('boot',device,check=False);run('bootstatus',device,'-b');run('install',device,str(app))
  run('status_bar',device,'override','--time','9:41','--dataNetwork','wifi','--wifiMode','active','--wifiBars','3','--cellularMode','active','--cellularBars','4','--batteryState','charged','--batteryLevel','100')
  folder=root/'store-screenshots'/label;folder.mkdir(parents=True,exist_ok=True)
  for name,args in [('01-device-names',[]),('02-signal-map',['-SignalScoutFullScreenScreenshotMode']),('03-signal-comparison',['-SignalScoutTrackingScreenshotMode'])]:
   run('terminate',device,bundle,check=False);run('launch',device,bundle,'-SignalScoutScreenshotMode',*args);time.sleep(4)
   run('io',device,'screenshot',str(folder/(name+'.png')))
   print(label,name,flush=True)
 finally:
  run('shutdown',device,check=False)
