import {decodeP6} from './frame.mjs';
const cwd='/tmp/nelua-wayland-smoke';
const socket='wayland-nelua';
const env={XDG_RUNTIME_DIR:cwd,WAYLAND_DISPLAY:socket};
const framePath=cwd+'/frame.ppm';
const opt={user:'root',timeout:4000};
const control=(...args)=>[args[0],args.slice(1)];
const sleep=(ms)=>new Promise(r=>setTimeout(r,ms));
async function awaitFor(action,what,maxMs=8000) {
  const until=Date.now()+maxMs;
  do {
    const r=await action();
    if(r)return r;
    await sleep(50);
  }while(Date.now()<until);
  throw new Error('Timed out waiting for '+what);
}
export async function openDemo(vm) {
  const guest=async(...args)=>{
    const [bin,argv]=control(...args);
    const r=await vm.exec(bin,argv,opt);
    if(r.exitCode!==0)throw new Error('Guest command failed: '+bin+' '+r.stderr);
    return r.stdout;
  };
  const vars=await guest('/bin/sh','-ec','printf "pid1=%s;net=%s" "$(readlink /proc/1/exe)" "$(ls /sys/class/net|tr "\\n" " ")"');
  if(!/^pid1=\/usr\/sbin\/theseus-init;net=(lo |dummy0 lo )$/.test(vars))throw Error('Unexpected guest identity: '+vars);
  await guest('/bin/mkdir','-m','700',cwd);
  const compositor=await vm.spawn('/opt/newayland', [socket,framePath], {cwd,env,user:'root'});
  await awaitFor(async()=>(await vm.exec('/usr/bin/test',['-S',cwd+'/'+socket],opt)).exitCode===0,'Wayland compositor socket');
  const client=await vm.spawn('/opt/newayland-client', [], {cwd,env,user:'root'});
  const refresh=async()=>{
    const r=await vm.exec('/bin/cat',[framePath],{...opt,encoding:'buffer'});
    if(r.exitCode!==0)return null;
    const bytes=r.stdout instanceof Uint8Array ? r.stdout : new Uint8Array(r.stdout);
    try{decodeP6(bytes);}catch{return null;}
    return bytes;
  };
  const digest=async bytes=>Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',bytes)),v=>v.toString(16).padStart(2,'0')).join('');
  let frame=await awaitFor(refresh,'first complete compositor-owned frame');
  let sha=await digest(frame);
  let busy=false;
  return {
    get frame(){return frame;},get sha(){return sha;},identity:vars,compositor,client,
    async key() {
      if(busy)throw Error('Input roundtrip already in progress');
      busy=true;
      try{
        // Browser Space maps to Linux evdev KEY_SPACE (57); no raw command text.
        await compositor.write('key 57 1\nkey 57 0\n');
        const next=await awaitFor(async()=>{
          const b=await refresh();
          if(!b)return null;
          const nextSha=await digest(b);
          return nextSha===sha?null:{b,nextSha};
        },'Wayland client repaint after key');
        frame=next.b;sha=next.nextSha;
        return frame;
      }finally{busy=false;}
    }
  };
}
