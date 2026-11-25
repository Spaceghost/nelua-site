// Paint only bytes emitted by the in-guest compositor, never synthetic pixels.
export function decodeP6(input) {
  const raw = input instanceof Uint8Array ? input : new Uint8Array(input);
  const max = 4 * 1024 * 1024;
  if(raw.byteLength < 12 || raw.byteLength > max) throw Error('frame payload size');
  let p = 0;
  const ws = n => n === 32 || n === 9 || n === 13 || n === 10;
  const token = () => {
    while(p < 96 && ws(raw[p])) p++;
    const from = p;
    while(p < 96 && raw[p] !== undefined && !ws(raw[p])) p++;
    if(p === from || p === 96) throw Error('malformed frame header');
    return String.fromCharCode(...raw.subarray(from,p));
  };
  const magic=token(), w=token(), h=token(), pixmax=token();
  if(magic!=='P6' || !/^[1-9][0-9]{0,3}$/.test(w) || !/^[1-9][0-9]{0,3}$/.test(h) || pixmax !== '255') throw Error('frame format');
  if(raw[p++] !== 10) throw Error('frame header requires LF delimiter');
  const width=+w,height=+h;
  if(width>1024 || height>768 || raw.length-p !== width*height*3) throw Error('frame dimensions or truncation');
  return {width,height,rgb:raw.subarray(p)};
}
export function paintP6(canvas, data) {
  const {width,height,rgb}=decodeP6(data);
  canvas.width=width;canvas.height=height;
  const ctx=canvas.getContext('2d',{alpha:false});
  const img=ctx.createImageData(width,height);
  for(let i=0,j=0;i<rgb.length;i+=3,j+=4) {
    img.data[j]=rgb[i];img.data[j+1]=rgb[i+1];img.data[j+2]=rgb[i+2];img.data[j+3]=255;
  }
  ctx.putImageData(img,0,0);
}
