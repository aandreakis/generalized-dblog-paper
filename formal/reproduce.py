#!/usr/bin/env python3
"""Reproduce the packaged formal checks using installed, pinned toolchains."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent
JAR_SHA256 = '936a262061c914694dfd669a543be24573c45d5aa0ff20a8b96b23d01e050e88'

def checksums():
    count = 0
    for line in (ROOT/'SHA256SUMS').read_text().splitlines():
        digest, name = line.split('  ',1)
        actual = hashlib.sha256((ROOT/name).read_bytes()).hexdigest()
        if digest != actual:
            raise RuntimeError('Checksum mismatch: '+name)
        count += 1
    print(f'PASS: {count} file checksums')

def isabelle(no_document=False):
    scratch = Path(tempfile.mkdtemp(prefix='gdblog-isabelle-'))
    for rel in ['dual_write_layer0','formal','dblog_framework/framework_core']:
        shutil.copytree(ROOT/rel,scratch/rel)
    env = dict(os.environ, USER_HOME=str(scratch/'user'))
    print('Isabelle scratch directory:',scratch,flush=True)
    command = ['isabelle','build','-b','-j','8','-o','quick_and_dirty=false']
    if no_document:
        # ROOT files explicitly enable PDFs, so suppress their variants too.
        command += ['-o','document=false','-o','document_variants=']
    command += ['-d','dual_write_layer0','-d','formal','-d','dblog_framework/framework_core',
                'DBLog_Virtual_Cuts','DBLog_Framework_Core']
    print('Isabelle command:', ' '.join(command), flush=True)
    subprocess.run(command,cwd=scratch,env=env,check=True)

def lean():
    scratch=Path(tempfile.mkdtemp(prefix='gdblog-lean-'))
    shutil.copytree(ROOT/'dblog_framework/lean',scratch/'lean')
    print('Lean scratch directory:',scratch,flush=True)
    subprocess.run(['lake','build'],cwd=scratch/'lean',check=True)

def tlc(jar,selected):
    if jar is None:
        raise RuntimeError('--jar /absolute/path/to/tla2tools.jar is required for TLC')
    jar=jar.resolve()
    if hashlib.sha256(jar.read_bytes()).hexdigest()!=JAR_SHA256:
        raise RuntimeError('TLC jar differs from the recorded 2.19 binary')
    scratch=Path(tempfile.mkdtemp(prefix='gdblog-tlc-'))
    for file in (ROOT/'dblog_framework/tla').iterdir():
        if file.suffix in ['.tla','.cfg']:
            shutil.copy2(file,scratch/file.name)
    runs=json.loads((ROOT/'tlc-runs.json').read_text())
    if selected:
        runs=[r for r in runs if r['run_id'] in selected]
        if len(runs)!=len(set(selected)):
            raise RuntimeError('Unknown or duplicate --run identifier')
    print('TLC scratch directory:',scratch,flush=True)
    for run in runs:
        log=scratch/(run['run_id']+'.log')
        command=['java','-cp',str(jar),'tlc2.TLC','-workers',str(run['workers']),
                 '-cleanup','-config',run['cfg'],run['spec']]
        with log.open('w') as stream:
            result=subprocess.run(command,cwd=scratch,stdout=stream,stderr=subprocess.STDOUT)
        text=log.read_text()
        if run['verdict']=='PASS':
            passed=result.returncode==0 and 'Model checking completed. No error has been found.' in text
        else:
            violation=re.search(r'Invariant (\w+) is violated',text)
            passed=result.returncode==12 and violation is not None and violation.group(1)==run['violated_invariant']
        if not passed:
            raise RuntimeError('Unexpected result in '+run['run_id']+'; inspect '+str(log))
        print(run['run_id']+': expected '+run['verdict']+' reproduced',flush=True)

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('check',choices=['checksums','isabelle','lean','tlc','all'])
    parser.add_argument('--jar',type=Path)
    parser.add_argument('--run',action='append',help='TLC run ID; repeat to select several')
    parser.add_argument('--no-document',action='store_true',
                        help='Check Isabelle proofs without generating PDFs or requiring LaTeX')
    args=parser.parse_args()
    if args.no_document and args.check not in ['isabelle','all']:
        parser.error('--no-document applies to isabelle or all')
    checksums()
    if args.check in ['isabelle','all']:
        isabelle(args.no_document)
    if args.check in ['lean','all']:
        lean()
    if args.check in ['tlc','all']:
        tlc(args.jar,args.run)
