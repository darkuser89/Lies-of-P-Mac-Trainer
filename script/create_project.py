#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Create a new trainer source project; never copy builds, saves or Git history."""
from pathlib import Path
import argparse,fnmatch,json,re,shutil,subprocess

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('destination',type=Path)
    parser.add_argument('--name',required=True)
    parser.add_argument('--bundle-id',required=True)
    parser.add_argument('--game-bundle-id',default='')
    parser.add_argument('--git',action='store_true',help='Initialize a new main branch, without a commit or remote.')
    args=parser.parse_args()
    source=Path(__file__).resolve().parent.parent
    dest=args.destination.expanduser().resolve()
    if dest==source or source in dest.parents or dest in source.parents:parser.error('Destination must be separate from the template.')
    if dest.exists():parser.error('Destination already exists; nothing overwritten.')
    if not args.name.strip() or any(c in args.name for c in '/\\\n\r'):parser.error('Invalid name.')
    if not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9.-]+',args.bundle_id):parser.error('Invalid bundle identifier.')
    entries=['Sources','Tests','Resources','script','docs','LICENSE','README.md','AGENTS.md','SKILL.md','.gitignore','.gitattributes']
    missing=[name for name in entries if not (source/name).exists()]
    if missing:parser.error('Template incomplete: '+', '.join(missing))
    config=json.loads((source/'Resources/TrainerConfig.json').read_text())
    config['app'].update(name=args.name,bundleIdentifier=args.bundle_id,version='0.1.0',build='1')
    config['profiles']=[{'id':'game','name':args.name+' – Adapter offen','enabled':False,'bundleIdentifier':args.game_bundle_id,'executable':'','uuids':[],'teamIdentifier':'','version':''}]
    excluded=['.git','.codex','__pycache__','build','Builds','DerivedData','*.pyc','*.app','*.dylib','*.o','*.a','*.dSYM','*.log','*.zip','*.dmg','*.sav','*.sav.*','*.bak','.DS_Store','.env','.env.*','*.p12','*.pem','*.key']
    def ignore_runtime(folder,names):
        return [name for name in names if (Path(folder)/name).is_symlink() or any(fnmatch.fnmatch(name,pattern) for pattern in excluded)]
    dest.mkdir(parents=True)
    for name in entries:
        src=source/name;target=dest/name
        if src.is_dir():shutil.copytree(src,target,ignore=ignore_runtime)
        else:shutil.copy2(src,target)
    (dest/'Resources/TrainerConfig.json').write_text(json.dumps(config,ensure_ascii=False,indent=2)+'\n')
    if args.git:subprocess.run(['git','init','-b','main',str(dest)],check=True)
    print('Created:',dest)
    print('Game profile remains disabled until the actual build and adapter are verified.')
if __name__=='__main__':main()
