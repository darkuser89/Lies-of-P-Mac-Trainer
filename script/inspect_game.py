#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Read game bundle metadata and signing information without launching/modifying it."""
from pathlib import Path
import argparse,json,plistlib,subprocess
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('app',type=Path)
args=parser.parse_args()
app=args.app.expanduser().resolve()
info=plistlib.loads((app/'Contents/Info.plist').read_bytes())
name=info.get('CFBundleExecutable')
if not isinstance(name,str) or not name or '/' in name:parser.error('Missing executable filename.')
binary=app/'Contents/MacOS'/name
result={'path':str(app),'bundleIdentifier':info.get('CFBundleIdentifier'),'version':info.get('CFBundleShortVersionString'),'executable':name}
commands={'file':['file',str(binary)],'uuids':['xcrun','dwarfdump','--uuid',str(binary)],'signing':['codesign','-dv','--verbose=2',str(app)],'signatureCheck':['codesign','--verify','--strict',str(app)]}
for key,command in commands.items():
 run=subprocess.run(command,capture_output=True,text=True)
 result[key]={'exitCode':run.returncode,'output':(run.stdout+run.stderr).strip()}
print(json.dumps(result,ensure_ascii=False,indent=2))
