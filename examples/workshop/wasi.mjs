// Only the process arguments and preview1 stdio calls used by the three examples.
export async function runConsole(module) {
  let memory;
  let text = '';
  const decoder = new TextDecoder();
  const exit = Symbol('exit');
  const view = () => new DataView(memory.buffer);
  const wasi = {
    args_sizes_get(argc, size) {
      view().setUint32(argc, 0, true);
      view().setUint32(size, 0, true);
      return 0;
    },
    args_get() { return 0; },
    fd_fdstat_get(fd, ptr) {
      if (fd !== 1 && fd !== 2) return 8;
      new Uint8Array(memory.buffer, ptr, 24).fill(0);
      view().setUint8(ptr, 2); // character device
      view().setBigUint64(ptr + 8, 64n, true); // FD_WRITE
      return 0;
    },
    fd_seek() { return 70; }, // console is not seekable
    fd_close(fd) { return fd === 1 || fd === 2 ? 0 : 8; },
    fd_write(fd, iovs, count, written) {
      if (fd !== 1 && fd !== 2) return 8;
      let total = 0;
      for (let i = 0; i < count; i++) {
        const start = view().getUint32(iovs + 8 * i, true);
        const size = view().getUint32(iovs + 8 * i + 4, true);
        text += decoder.decode(new Uint8Array(memory.buffer, start, size), {stream: true});
        total += size;
      }
      view().setUint32(written, total, true);
      return 0;
    },
    proc_exit(code) {
      if (code === 0) throw exit;
      throw new Error('Program exited with status ' + code);
    },
  };
  const instance = await WebAssembly.instantiate(module, {wasi_snapshot_preview1: wasi});
  memory = instance.exports.memory;
  try { instance.exports._start(); } catch (reason) { if (reason !== exit) throw reason; }
  return text + decoder.decode();
}
