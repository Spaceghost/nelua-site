// Optional source-only distribution adapter for hosts with a 25 MiB file cap.
// Has not replaced the browser QA path.
const sizeExpected = 3170304;
const unit = 1024 * 1024;
const hex = a => Array.from(a,v=>v.toString(16).padStart(2,'0')).join('');
export function chunkDisk(manifest,fetched) {
  if(manifest.size!==sizeExpected||manifest.unit!==unit||
    !Array.isArray(manifest.sha256)||manifest.sha256.length!==Math.ceil(sizeExpected/unit)||
    manifest.sha256.some(h=>!/^[0-9a-f]{64}$/.test(h)))throw Error('unexpected disk manifest');
  const known = [...manifest.sha256], cache=new Map();
  async function piece(i){
    const present=cache.get(i);
    if(present){cache.delete(i);cache.set(i,present);return present;}
    const load=(async()=>{
      const a=await fetched(i);
      const b=a instanceof Uint8Array?a:new Uint8Array(a);
      if(b.length!==Math.min(unit,sizeExpected-i*unit)||
        hex(new Uint8Array(await crypto.subtle.digest('SHA-256',b)))!==known[i])throw Error('disk chunk '+i+' changed');
      return b;
    })();
    cache.set(i,load);
    if(cache.size>6)cache.delete(cache.keys().next().value);
    try{return await load;}catch(e){if(cache.get(i)===load)cache.delete(i);throw e;}
  }
  return {size:sizeExpected,readOnly:true,
    async read(off,views){
      if(!Number.isSafeInteger(off)||off<0||off+views.reduce((n,v)=>n+v.length,0)>sizeExpected)throw Error('disk read outside pinned image');
      for(const v of views)for(let at=0;at<v.length;){
        const base=off%unit, b=await piece(Math.floor(off/unit)), n=Math.min(b.length-base,v.length-at);
        v.set(b.subarray(base,base+n),at);off+=n;at+=n;
      }
    },
    write(){throw Error('read-only disk');}
  };
}
