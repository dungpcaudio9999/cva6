#!/usr/bin/env python3
"""Read-only source/build preflight. No fetching, installation or RTL mutation.

Usage: python3 docs/dungpc/evidence/collect_baseline.py --out /tmp/cva6-baseline
The output is a source inventory, NOT an elaborated active file list.
"""
import argparse
import collections
import datetime
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[3]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
out = args.out.resolve()
out.mkdir(parents=True, exist_ok=True)

def run(name, command):
    p = subprocess.run(command, cwd=ROOT, text=True, stdout=subprocess.PIPE,
                       stderr=subprocess.STDOUT, timeout=60)
    (out / name).write_text('$ ' + ' '.join(command) + '\n' + p.stdout +
                            f'\nEXIT_STATUS={p.returncode}\n')
    return p.stdout, p.returncode

head, _ = run('git-head.log', ['git', 'rev-parse', 'HEAD'])
run('git-status.log', ['git', 'status', '--short'])
run('submodules.log', ['git', 'submodule', 'status', '--recursive'])
patch = subprocess.check_output(['git', 'diff', 'HEAD', '--binary', '--', '.',
                                ':!docs/dungpc'], cwd=ROOT)
(out / 'source-working-tree.patch').write_bytes(patch)
names = subprocess.check_output(['git', 'ls-files', '-z'], cwd=ROOT).decode().split('\0')
files = [p for p in names if p and not p.startswith('docs/dungpc/') and (ROOT / p).is_file()]
hashes = [(p, hashlib.sha256((ROOT / p).read_bytes()).hexdigest()) for p in sorted(files)]
(out / 'source-sha256.txt').write_text(''.join(f'{digest}  {p}\n' for p, digest in hashes))
inventory = collections.Counter()
for p in files:
    inventory[(p.split('/')[0], Path(p).suffix)] += 1
(out / 'inventory.json').write_text(json.dumps([
    {'directory': d, 'extension': e, 'count': n} for (d, e), n in sorted(inventory.items())
], indent=2) + '\n')
tools = {}
for name in ['make', 'python3', 'gcc', 'g++', 'verilator', 'iverilog', 'vvp', 'yosys',
             'sby', 'slang', 'bender', 'spike', 'riscv64-unknown-elf-gcc', 'vcs', 'vsim', 'xrun']:
    path = shutil.which(name)
    tools[name] = path
    if path and name in ['make', 'python3', 'gcc', 'g++', 'verilator', 'iverilog']:
        run(f'tool-{name.replace("+", "p")}.log', [path, '-V' if name == 'iverilog' else '--version'])
env = {k: os.environ.get(k, '<UNSET>') for k in
       ['CVA6_REPO_DIR', 'TARGET_CFG', 'RISCV', 'VERILATOR_INSTALL_DIR', 'HPDCACHE_DIR', 'SPIKE_TANDEM']}
mapping = {'CVA6_REPO_DIR': str(ROOT), 'TARGET_CFG': 'cv64a6_imafdc_sv39',
           'HPDCACHE_DIR': str(ROOT / 'core/cache_subsystem/hpdcache')}
entries = []
for line_no, raw in enumerate((ROOT / 'core/Flist.cva6').read_text().splitlines(), 1):
    line = raw.split('//', 1)[0].strip()
    if not line:
        continue
    expanded = re.sub(r'\$\{([^}]+)\}', lambda m: mapping.get(m[1], m[0]), line)
    inc = expanded.startswith('+incdir+')
    p = Path(expanded.removeprefix('+incdir+'))
    if not p.is_absolute():
        p = ROOT / p
    entries.append({'line': line_no, 'kind': 'include' if inc else 'source',
                    'path': str(p.relative_to(ROOT)) if p.is_relative_to(ROOT) else str(p),
                    'exists': p.is_dir() if inc else p.is_file()})
(out / 'flist-preflight.json').write_text(json.dumps(entries, indent=2) + '\n')
_, make_rc = run('make-verilate-dry-run.log', ['make', '-n', 'verilate', 'target=cv64a6_imafdc_sv39'])
summary = {'baseline': 'BASE-01', 'configuration': 'CFG-01',
           'timestamp_utc': datetime.datetime.now(datetime.timezone.utc).isoformat(),
           'head': head.strip(), 'host': os.uname().sysname + ' ' + os.uname().machine,
           'tools_on_path': tools, 'selected_environment': env,
           'tracked_regular_files_excluding_analysis': len(files),
           'source_patch_sha256': hashlib.sha256(patch).hexdigest(),
           'source_manifest_sha256': hashlib.sha256((out / 'source-sha256.txt').read_bytes()).hexdigest(),
           'flist_sources': sum(x['kind'] == 'source' for x in entries),
           'flist_missing_sources': sum(x['kind'] == 'source' and not x['exists'] for x in entries),
           'make_dry_run_exit': make_rc,
           'limits': 'Textual preflight only; no preprocessing, elaboration, HDL simulation or sign-off.'}
(out / 'baseline.json').write_text(json.dumps(summary, indent=2) + '\n')
print(json.dumps(summary, indent=2))
