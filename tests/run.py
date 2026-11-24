#!/usr/bin/env python3
"""Run the KOMPAS tests on the tools in build/ (make first).

Usage: run.py [-u] [-v] [name...]

A case is a directory tests/<case> with input files and 'steps', one
step per line, run on a fresh database:
  servis|ttc|gen|mad FILE     the tool with FILE on standard input
  prog FILE.pas [INPUT]       kpc, then run with INPUT
  native FILE.pas             a Free Pascal program on the kdb unit
The outputs, each after a line '== step', are compared with expected.txt.

tests/severov/<PROG>.pas are application programs of 1988-89 on the
databases the gold-* cases load: each must compile, and <PROG>.in, if
present, is a session compared with <PROG>.out.  SETUP sessions run first
on the same database (they make its data).

-u writes the expected outputs instead (review the diff), -v prints diffs.
"""
import argparse
import difflib
import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TESTS = ROOT / 'tests'
BIN = ROOT / 'build' / 'bin'
LIB = ROOT / 'build' / 'lib'
WORK = ROOT / 'build' / 'test'
SEVEROV = TESTS / 'severov'

# program: schema of the database it works on
PROGRAMS = {
    'SKLMON': 'ck0', 'SKLOTD': 'ck0', 'SKLCAR': 'ck0', 'SKLOTC': 'ck0',
    'AMOMON': 'am0', 'AMOOTD': 'am0', 'AMOCAR': 'am0', 'AMOOTC': 'am0',
    'AMOGRU': 'am0', 'ZATMON': 'zt0', 'ZATOTD': 'zt0', 'ZATCOF': 'zt0',
    'ZATZAT': 'zt0', 'ZATNAK': 'zt0', 'ZATRTE': 'zt0', 'ZATTAB': 'zt0',
}
# sessions run before a program's own on the same database
SETUP = {'ZATZAT': ['ZATRTE'], 'ZATTAB': ['ZATNAK', 'ZATRTE', 'ZATZAT']}


def env(db):
    return dict(os.environ, MARS_DIR=str(db), PATH=f'{BIN}:{os.environ["PATH"]}')


def sh(cmd, cwd, e, stdin=None, timeout=600):
    r = subprocess.run(cmd, cwd=cwd, env=e, input=stdin, capture_output=True,
                       timeout=timeout)
    return r.returncode, (r.stdout + r.stderr).decode('utf-8', 'replace')


def run_case(case):
    w = WORK / case.name
    if w.exists():
        shutil.rmtree(w)
    w.mkdir(parents=True)
    for f in case.iterdir():
        shutil.copy(f, w / f.name)
    e = env(w / 'db')
    out = []
    for step in (case / 'steps').read_text(encoding='utf-8').splitlines():
        if not step.strip() or step.startswith('#'):
            continue
        out.append(f'== {step}')
        tool, *args = step.split()
        if tool == 'prog':
            base = args[0].rsplit('.', 1)[0]
            rc, o = sh([str(BIN / 'kpc'), args[0]], w, e)
            if rc == 0:
                inp = ' '.join(args[1:]).encode() + b'\n' if len(args) > 1 else b''
                rc, o = sh(['./' + base], w, e, inp)
        elif tool == 'native':
            base = args[0].rsplit('.', 1)[0]
            rc, o = sh(['fpc', '-v0e', '-l-', f'-Fu{LIB}', f'-FU{w}', f'-o{base}', args[0]],
                       w, e)
            if rc == 0:
                rc, o = sh(['./' + base], w, e)
        else:
            rc, o = sh([str(BIN / tool)] + args[1:], w, e, (w / args[0]).read_bytes())
        out += [x.rstrip() for x in o.splitlines()]
        if rc != 0:
            out.append(f'== exit {rc}')
    return out


def compare(name, out, exp, update, verbose):
    if update:
        exp.write_text('\n'.join(out) + '\n', encoding='utf-8')
        print(f'{name:24s} WRITTEN')
        return True
    want = exp.read_text(encoding='utf-8').splitlines() if exp.exists() else []
    if out == want:
        print(f'{name:24s} MATCH')
        return True
    print(f'{name:24s} DIFF')
    if verbose:
        print('\n'.join(difflib.unified_diff(want, out, 'expected', 'got', lineterm='')))
    return False


def build_prog(name, verbose):
    """Compile tests/severov/<name>.pas against the database of its schema."""
    w = WORK / 'severov' / name
    w.mkdir(parents=True, exist_ok=True)
    shutil.copy(SEVEROV / (name + '.pas'), w / 'prog.pas')
    db = WORK / f'gold-{PROGRAMS[name]}' / 'db'
    if not db.exists():
        print(f'{name:24s} NO DATABASE (run the gold-{PROGRAMS[name]} case)')
        return False
    rc, o = sh([str(BIN / 'kpc'), 'prog.pas'], w, env(db))
    if rc != 0:
        print(f'{name:24s} BUILD FAILED')
        if verbose:
            print('\n'.join(o.splitlines()[:30]))
        return False
    print(f'{name:24s} BUILT')
    return True


def run_session(name, update, verbose):
    w = WORK / 'severov' / ('run-' + name)
    if w.exists():
        shutil.rmtree(w)
    w.mkdir(parents=True)
    shutil.copytree(WORK / f'gold-{PROGRAMS[name]}' / 'db', w / 'db')
    e = env(w / 'db')
    for pre in SETUP.get(name, []):
        subprocess.run([str(WORK / 'severov' / pre / 'prog')], cwd=w, env=e,
                       input=(SEVEROV / (pre + '.in')).read_bytes(),
                       capture_output=True, timeout=60)
    try:
        r = subprocess.run([str(WORK / 'severov' / name / 'prog')], cwd=w, env=e,
                           input=(SEVEROV / (name + '.in')).read_bytes(),
                           capture_output=True, timeout=60)
        out = r.stdout.decode('utf-8', 'replace').splitlines()
        if r.returncode:
            out.append(f'== exit {r.returncode}')
    except subprocess.TimeoutExpired:
        out = ['== timeout']
    out = [x.rstrip() for x in out]
    return compare(name + ' session', out, SEVEROV / (name + '.out'), update, verbose)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('-u', action='store_true', help='write expected outputs')
    ap.add_argument('-v', action='store_true', help='print diffs')
    ap.add_argument('names', nargs='*')
    a = ap.parse_args()
    if not (BIN / 'predt').exists():
        sys.exit('build/bin: not built, run make')
    cases = sorted(p.name for p in TESTS.iterdir() if (p / 'steps').exists())
    want = set(a.names)
    ok = total = 0
    for n in cases:
        if want and n not in want:
            continue
        total += 1
        ok += compare(n, run_case(TESTS / n), TESTS / n / 'expected.txt', a.u, a.v)
    built = set()
    for n in PROGRAMS:
        if want and n not in want and 'severov' not in want:
            continue
        total += 1
        if build_prog(n, a.v):
            ok += 1
            built.add(n)
    for n in PROGRAMS:
        if (want and n not in want and 'severov' not in want) or \
           not (SEVEROV / (n + '.in')).exists():
            continue
        total += 1
        if n in built and all(p in built for p in SETUP.get(n, [])):
            ok += run_session(n, a.u, a.v)
        else:
            print(f'{n + " session":24s} SKIPPED (not built)')
    print(f'{ok} of {total} passed')
    sys.exit(0 if ok == total else 1)


if __name__ == '__main__':
    main()
