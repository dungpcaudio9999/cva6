#!/usr/bin/env python3
"""Compile/run actual configuration packages using Questa in an isolated output.
Usage: python3 docs/dungpc/evidence/run_config_probe.py --out /tmp/cva6-config-probe
"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parents[3]
p = argparse.ArgumentParser(description=__doc__)
p.add_argument('--out', type=Path, required=True)
out = p.parse_args().out.resolve()
out.mkdir(parents=True, exist_ok=True)
records = []

def run(label, cmd):
    try:
        r = subprocess.run(cmd, cwd=out, text=True, stdout=subprocess.PIPE,
                           stderr=subprocess.STDOUT, timeout=45)
        status, output = r.returncode, r.stdout
    except subprocess.TimeoutExpired as e:
        status = 124
        output = e.stdout or b''
        if isinstance(output, bytes):
            output = output.decode(errors='replace')
        output += '\nTIMEOUT after 45 seconds\n'
    (out / (label + '.log')).write_text('$ ' + ' '.join(cmd) + '\n' + output + f'\nEXIT_STATUS={status}\n')
    records.append({'label': label, 'command': cmd, 'exit': status})
    return status, output

sources = ['core/include/config_pkg.sv', 'core/include/cv64a6_imafdc_sv39_config_pkg.sv',
           'core/include/build_config_pkg.sv', 'docs/dungpc/evidence/tb_config.sv']
(out / 'inputs.sha256').write_text(''.join(
    hashlib.sha256((root / s).read_bytes()).hexdigest() + '  ' + s + '\n' for s in sources))
run('version', ['vsim', '-version'])
rc, _ = run('library', ['vlib', 'work'])
if rc == 0:
    rc, _ = run('compile', ['vlog', '-sv', '-work', 'work'] + [str(root / s) for s in sources])
if rc == 0:
    rc, output = run('positive', ['vsim', '-c', '-onfinish', 'stop', 'work.tb_config',
                                '-do', 'onerror {quit -code 1}; run -all; quit -code 0'])
    if rc == 0 and 'PASS CONFIG checks=16' in output:
        run('negative', ['vsim', '-c', '-onfinish', 'stop', 'work.tb_config', '+CORRUPT_EXPECTATION',
                         '-do', 'onbreak {quit -code 1}; onerror {quit -code 1}; run -all; quit -code 0'])
(out / 'commands.json').write_text(json.dumps(records, indent=2) + '\n')
print(json.dumps(records, indent=2))
