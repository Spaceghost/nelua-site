#!/usr/bin/env python3
"""Run correctness-gated, interleaved static archive link timings."""
import argparse
import csv
import hashlib
import json
import os
import platform
import random
import shutil
import statistics
import subprocess
import tempfile
import time
from pathlib import Path
from check_archives import assemble, basic_fixtures, make_archive, invoke

p=argparse.ArgumentParser()
for name in ("linker","sdk","out"):
    p.add_argument(name,type=Path)
p.add_argument("--old",type=Path);p.add_argument("--first",type=Path)
p.add_argument("--tools",type=Path);p.add_argument("--zig",type=Path)
p.add_argument("--rounds",type=int,default=13);p.add_argument("--cpus",default="1,2,3,4")
a=p.parse_args()
sdk=a.sdk.resolve();out=a.out.resolve();out.mkdir(parents=True,exist_ok=True)
link=a.linker.resolve();old=a.old.resolve() if a.old else None
first=a.first.resolve() if a.first else None
tools=a.tools.resolve() if a.tools else None
affinity=[int(n) for n in a.cpus.split(",")];os.sched_setaffinity(0,affinity)
with tempfile.TemporaryDirectory(prefix="archive-bench-",dir=os.environ.get("TMPDIR")) as tmp:
    d=Path(tmp);os.chdir(d)
    start,sys,work,mid,base,unused,simple=basic_fixtures(d,sdk)
    lib=sdk/"libnelibc.a";rt=sdk/"tcc/libtcc1.a"
    ex=d/"syscall.o";ex.write_bytes(invoke(["ar","p",lib,"syscall-asm.o"]).stdout)
    many=[];chain=[]
    for i in range(256):
        name="work" if i==255 else f"other{i}"
        many.append(assemble(d/f"sparse-{i}.o",f".text\n.globl {name}\n{name}: mov $42,%eax\n ret"))
        name="work" if i==0 else f"part{i}"
        code=f"call part{i+1}\n add $1,%eax" if i<255 else "mov $43,%eax"
        chain.append(assemble(d/f"chain-{i}.o",f".text\n.globl {name}\n{name}: {code}\n ret"))
    sparse=make_archive(d/"libmany.a",*many)
    reverse=make_archive(d/"libreverse.a",*reversed(chain))
    src=d/"sdk-allocator.c";src.write_text("""#include <stdlib.h>
#include <unistd.h>
int main(void) {
    int *a=malloc(sizeof *a), *b=malloc(sizeof *b);
    if (!a || !b || a==b || getpid()<=0) return 1;
    *a=19; *b=23;
    int result=*a+*b;
    free(b); free(a);
    return result;
}
""")
    tcc=[str(sdk/"tcc/tcc"),"-B"+str(sdk/"tcc")]
    obj=d/"allocator.o"
    invoke([*tcc,"-nostdinc","-DNELIBC_STANDALONE","-I"+str(sdk/"include"),"-I"+str(sdk/"tcc/include"),"-I"+str(sdk/"uapi"),"-c",src,"-o",obj])
    cases={"explicit-syscall":[start,sys,ex], "sdk-one-member":[start,sys,lib],
           "one-of-256":[start,sparse], "reverse-chain-256":[start,reverse],
           "whole-256":[start,"WHOLE",sparse,"LAZY"],
           "whole-sdk-allocator":[obj,"WHOLE",lib,"LAZY",rt]}
    toolmap={"nelinker":[str(link)],"GNU-bfd":["ld.bfd","-static","-s","-e","_start"],
             "GNU-gold":["ld.gold","-static","-s","-e","_start"],
             "TinyCC":[*tcc,"-nostdlib","-static","-s","-Wl,-e,_start"]}
    if old:toolmap["nelinker-object-only"]=[str(old)]
    if first:toolmap["nelinker-first-index"]=[str(first)]
    if tools:
        toolmap["LLD-14"]=[str(tools/"debian/usr/bin/ld.lld-14"),"-static","-s","-e","_start"]
        toolmap["mold"]=[str(tools/"mold"),"-static","-s","-e","_start"]
        toolmap["Wild"]=[str(tools/"wild"),"--no-gc-sections","-static","-s","-e","_start"]
        os.environ["LD_LIBRARY_PATH"]=str(tools/"debian/usr/lib/x86_64-linux-gnu")+":"+str(tools/"debian/usr/lib/llvm-14/lib")
    if a.zig:
        toolmap["LLD-22-Zig"]=[str(a.zig.resolve()),"ld.lld","-static","-s","-e","_start"]
    def digest(f):
        with open(f,"rb") as stream:return hashlib.file_digest(stream,"sha256").hexdigest()
    info={"system":platform.uname()._asdict(),"cpus":affinity,"load-start":os.getloadavg(),"rounds":a.rounds,"seed":32499,
          "commands":{},"inputs":{},"binary_sha256":{},"versions":{}}
    for name,cmd in toolmap.items():
        exe=shutil.which(cmd[0])
        if exe:
            info["binary_sha256"][name]=digest(exe)
            if not name.startswith("nelinker"):
                prefix=cmd[:2] if name=="LLD-22-Zig" else cmd[:1]
                r=subprocess.run([*prefix,"-v" if name=="TinyCC" else "--version"],capture_output=True,text=True)
                lines=(r.stdout or r.stderr).splitlines();info["versions"][name]=lines[0] if lines else ""
    for name,items in cases.items():info["inputs"][name]={x.name:digest(x) for x in items if isinstance(x,Path)}
    exe=d/"program"
    def build(tool,case):
        cmd=[*toolmap[tool]]
        if tool!="nelinker-object-only" and tool.startswith("nelinker") and case in ("sdk-one-member","explicit-syscall","whole-sdk-allocator"):
            cmd+=["--tcc-relocs"]
        cmd+=["-o",str(exe)]
        for x in cases[case]:
            if x in ("WHOLE","LAZY"):
                x="--whole-archive" if x=="WHOLE" else "--no-whole-archive"
                if tool=="TinyCC":x="-Wl,"+x
            cmd.append(str(x))
        return cmd
    def measure(cmd):
        exe.unlink(missing_ok=True)
        t=time.perf_counter_ns()
        r=subprocess.run(cmd,stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=12)
        ns=time.perf_counter_ns()-t
        if r.returncode:raise ValueError("link: "+r.stderr.decode(errors="replace").strip())
        try:run=subprocess.run([exe],capture_output=True,timeout=1)
        except subprocess.TimeoutExpired:raise ValueError("linked program exceeded 1 s runtime deadline")
        if run.returncode!=42:raise ValueError("program returned "+str(run.returncode))
        return ns,exe.stat().st_size
    valid=[];status={}
    for case in cases:
        for tool in toolmap:
            key=case+"/"+tool
            cmd=build(tool,case);info["commands"][key]=cmd
            try:
                _,size=measure(cmd)
                status[key]={"passed":True,"file_bytes":size}
                valid.append((case,tool))
            except (ValueError,OSError,subprocess.SubprocessError) as e:status[key]={"passed":False,"reason":str(e)}
    rounds=[];rng=random.Random(info["seed"])
    for rep in range(a.rounds+1):
        order=list(valid);rng.shuffle(order)
        for case,tool in order:
            ns,size=measure(build(tool,case))
            if rep:rounds.append((rep,case,tool,ns))
    info["load-end"]=os.getloadavg()
    with (out/"samples.csv").open("w",newline="") as f:
        w=csv.writer(f);w.writerow(["round","case","tool","wall_ns"]);w.writerows(rounds)
    with (out/"summary.csv").open("w",newline="") as f:
        w=csv.writer(f);w.writerow(["case","tool","n","median_ms","q1_ms","q3_ms","file_bytes"])
        for case,tool in valid:
            t=[n/1e6 for _,c,k,n in rounds if c==case and k==tool]
            med=statistics.median(t)
            q=statistics.quantiles(t,n=4,method="inclusive") if len(t)>1 else [med]*3
            w.writerow([case,tool,len(t),f"{med:.4f}",f"{q[0]:.4f}",f"{q[2]:.4f}",status[case+"/"+tool]["file_bytes"]])
    (out/"status.json").write_text(json.dumps(status,indent=2)+"\n")
    (out/"metadata.json").write_text(json.dumps(info,indent=2)+"\n")
    print(len(rounds),"timings,",len(valid),"qualified pairs")
