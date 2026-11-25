import {createKernel} from './runtime/web.mjs';
import {openDemo} from './transport.mjs';
import {chunkDisk} from './chunk-disk.mjs';
import {paintP6} from './frame.mjs';
const start=document.getElementById('boot');
const canvas=document.getElementById('display');
const status=document.getElementById('state');
const asset=n=>new URL('./runtime/'+n,import.meta.url);
const send=document.getElementById('send-space');
let demo, vm, working=false;
function receipt(){
  document.body.dataset.receipt=JSON.stringify({
    isolated:crossOriginIsolated,
    resources:performance.getEntriesByType('resource').map(e=>({
      path:new URL(e.name).pathname, body:e.encodedBodySize, transfer:e.transferSize,
      status:e.responseStatus, ms:e.responseEnd
    })),
    marks:performance.getEntriesByType('mark').map(e=>[e.name,e.startTime])
  });
}
start.onclick=async()=>{
  start.disabled=true;
  try {
    status.textContent='Loading ARM64 Theseus…';
    const get=async n=>{
      const res=await fetch(asset(n));
      if(!res.ok)throw Error(n+' HTTP '+res.status);
      return new Uint8Array(await res.arrayBuffer());
    };
    const [manifestBytes,initrd]=await Promise.all([get('disk/manifest.json'),get('theseus.cpio.gz')]);
    const hex=a=>Array.from(new Uint8Array(a),x=>x.toString(16).padStart(2,'0')).join('');
    if(hex(await crypto.subtle.digest('SHA-256',manifestBytes))!=='f7239c4d47810416a188e4dbf120c868a52f6172af59d10fb5cf56dbe1c4eaf0')throw Error('Unexpected manifest digest');
    const manifest=JSON.parse(new TextDecoder().decode(manifestBytes));
    const disk=chunkDisk(manifest,async i=>get('disk/'+String(i).padStart(2,'0')+'.chunk'));
    vm=await createKernel({memoryMiB:512,kernel:asset('unkernel.wasm'),distro:disk,initrd,cmdline:'console=hvc0 rdinit=/init theseus.pid1=1 theseus.rescue=off',shm:true});
    demo=await openDemo(vm);
    paintP6(canvas,demo.frame);
    document.body.dataset.frame=demo.sha;
    performance.mark('first-guest-frame-written');receipt();
    status.textContent='Guest frame live. Click the canvas and press Space.';
    send.disabled=false;
    canvas.focus();
  }catch(e){if(vm)await vm.stop().catch(()=>{});receipt();status.textContent='Boot failed: '+e.message;start.disabled=false;console.error(e);}
};
async function sendSpace(){
  if(!demo||working)return;
  working=true;
  send.disabled=true;
  try {
    paintP6(canvas,await demo.key());
    document.body.dataset.frame=demo.sha;
    performance.mark('guest-input-frame-written');receipt();
    status.textContent='Wayland client repainted after guest keyboard input.';
  }catch(e){status.textContent='Guest input failed: '+e.message;console.error(e);}
  finally{working=false;send.disabled=false;}
}
send.addEventListener('click',sendSpace);
canvas.addEventListener('keydown',e=>{
  if(e.code!=='Space'||e.repeat)return;
  e.preventDefault();
  void sendSpace();
});
