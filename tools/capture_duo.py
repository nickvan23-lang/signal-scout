#!/usr/bin/env python3
"""Capture actual Duo displays through verified fold transitions, preserving one app process."""
import argparse,json,os,re,subprocess,time
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--device',required=True);p.add_argument('--bundle',required=True);p.add_argument('--out',required=True);p.add_argument('--landscape-only',action='store_true');a=p.parse_args()
out=Path(a.out);out.mkdir(parents=True,exist_ok=False)
helper=Path(__file__).parent/'duoctl'/'duoctl'
def run(args,timeout=60):
 r=subprocess.run(args,capture_output=True,text=True,timeout=timeout)
 if r.returncode:raise RuntimeError(str(args)+': '+r.stderr[-2000:]+r.stdout[-2000:])
 return r.stdout
launch=run(['xcrun','simctl','launch',a.device,a.bundle]);match=re.search(r': (\d+)\s*$',launch)
if not match:raise RuntimeError('Cannot verify app PID: '+launch)
pid=int(match.group(1));records=[]
poses=[('cover-portrait','close','portrait','cover'),('inner-landscape','open','landscape','inner'),('inner-portrait','open','portrait','inner'),('book-landscape','half','landscape','inner'),('cover-return','close','portrait','cover')]
if a.landscape_only:
 poses=[('cover-landscape','close','landscape','cover'),('inner-landscape','open','landscape','inner'),('book-landscape','half','landscape','inner'),('cover-return','close','landscape','cover')]
try:
 for name,pose,orientation,screen in poses:
  run(['python3',str(helper),'-d',a.device,pose],timeout=90)
  try:
   state=json.loads(run(['python3',str(helper),'-d',a.device,'rotate',orientation],timeout=90))
  except RuntimeError:
   if not a.landscape_only:raise
   orientation='landscape-flipped'
   state=json.loads(run(['python3',str(helper),'-d',a.device,'rotate',orientation],timeout=90))
  if state['activeScreen']!=screen or state['orientation']!=orientation:raise RuntimeError('Pose readback mismatch '+str(state))
  os.kill(pid,0)
  time.sleep(2)
  image=out/(name+'.jpg')
  run(['xcrun','simctl','io',a.device,'screenshot','--type=jpeg','--display='+str(state['displayId']),str(image)])
  sizes=run(['sips','-g','pixelWidth','-g','pixelHeight',str(image)])
  w=int(re.search(r'pixelWidth: (\d+)',sizes).group(1));h=int(re.search(r'pixelHeight: (\d+)',sizes).group(1))
  expected=(1398,2034) if screen=='cover' else (2007,2853)
  if sorted([w,h])!=sorted(expected):raise RuntimeError('Unexpected screenshot dimensions '+str((w,h)))
  records.append({'name':name,'state':state,'processId':pid,'sameProcessAlive':True,'screenshot':image.name,'width':w,'height':h})
  (out/'poses.json').write_text(json.dumps({'bundle':a.bundle,'poses':records,'complete':False},indent=2)+'\n')
 (out/'poses.json').write_text(json.dumps({'bundle':a.bundle,'poses':records,'complete':True,'scope':'Verified simulator pose/display, screenshot dimensions, and same live app process. Visual layout and task behavior require separate review.'},indent=2)+'\n')
except Exception as e:
 try:
  diagnostic=json.loads(run(['python3',str(helper),'-d',a.device,'state']))
  (out/'failure-state.json').write_text(json.dumps(diagnostic,indent=2)+'\n')
  run(['xcrun','simctl','io',a.device,'screenshot','--type=jpeg','--display='+str(diagnostic['displayId']),str(out/'failure.jpg')])
 except Exception as diagnostic_error:
  (out/'diagnostic-error.txt').write_text(str(diagnostic_error))
 (out/'failure.json').write_text(json.dumps({'error':str(e),'completedPoses':len(records)},indent=2)+'\n');raise
