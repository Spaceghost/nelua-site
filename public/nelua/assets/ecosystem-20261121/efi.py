import csv, os, runpy, sys, time
from pathlib import Path
from types import SimpleNamespace

p=Path.cwd()
helpers=runpy.run_path('/tools/tests/smoke-ovmf.py')
args=SimpleNamespace(qemu='qemu-system-x86_64',accel='tcg',interactive=False,logs=p)
os.sched_setaffinity(0,{0})
writer=csv.writer(sys.stdout)
writer.writerow(['round','launch_to_menu_s','selection_to_startimage_s','startimage_to_command_s'])
for r in range(4):
    start=time.monotonic()
    with helpers['console'](args,p/'core.img',p/'OVMF_VARS.fd',p/'OVMF_CODE.fd',str(r)) as con:
        con.expect(rb'Q  Return to firmware',90)
        menu=time.monotonic()
        con.send(b'1')
        con.expect(rb'Starting \\boot\\vmlinuz',60)
        kernel=time.monotonic()
        con.expect(rb'[$#] ',120)
        con.send(b"printf 'PID1='; readlink /proc/1/exe\r")
        con.expect(rb'PID1=/bin/theseus-init',30)
        result=time.monotonic()
        con.send(b'kill -USR2 1\r')
        assert con.wait_exit(45)==0
        writer.writerow([r,menu-start,kernel-menu,result-kernel])
        sys.stdout.flush()
