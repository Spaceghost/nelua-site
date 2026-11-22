import { Terminal } from '@xterm/xterm'
import { FitAddon } from '@xterm/addon-fit'
import { openpty } from 'xterm-pty'

const assets = new URL('vm/', globalThis.location.href)
const roms = [
	['bios-256k.bin', 0, 262144]
	['efi-virtio.rom', 262144, 422912]
	['kvmvapic.bin', 422912, 432128]
	['linuxboot_dma.bin', 432128, 433664]
	['vgabios-stdvga.bin', 433664, 473088]
]

def fetchAsset name
	const response = await fetch(new URL(name, assets))
	throw new Error("Could not load {name} (HTTP {response.status}).") unless response.ok
	response

def loadWasm
	const response = await fetchAsset('qemu-system-x86_64.wasm.gz')
	const stream = response.body.pipeThrough(new DecompressionStream('gzip'))
	new Response(stream).arrayBuffer!

const start = document.querySelector('#theseus-start')
const reset = document.querySelector('#theseus-reset')
const status = document.querySelector('#theseus-status')
const consolePane = document.querySelector('#theseus-console')
const stage = document.querySelector('#theseus-terminal')
const runExample = document.querySelector('#theseus-example')

def boot
	if !globalThis.crossOriginIsolated or !globalThis.DecompressionStream
		status.textContent = 'This demo needs a browser with WebAssembly threads and gzip streaming support.'
		return

	start.disabled = yes
	reset.hidden = no
	status.textContent = 'Downloading the emulator and boot image…'
	try
		const script = new URL('out.js', assets).href
		const [qemu, wasm, kernel, initrd, firmware] = await Promise.all([
			import(script)
			loadWasm!
			fetchAsset('vmlinuz-lts').then(do(response) response.arrayBuffer!)
			fetchAsset('nebox.cpio.gz').then(do(response) response.arrayBuffer!)
			fetchAsset('load-rom.data').then(do(response) response.arrayBuffer!)
		])

		status.textContent = 'Booting Theseus. Wait for the shell prompt.'
		consolePane.hidden = no
		const terminal = new Terminal({
			fontSize: 14
			fontFamily: 'ui-monospace, monospace'
			cursorBlink: yes
			theme: { background: '#171a20', foreground: '#f1f4f8' }
		})
		const fit = new FitAddon
		terminal.loadAddon(fit)
		terminal.open(stage)
		fit.fit!
		const resize = new ResizeObserver(do fit.fit!)
		resize.observe(stage)
		const { master, slave } = openpty!
		terminal.loadAddon(master)
		terminal.focus!

		const instance = await qemu.default({
			wasmBinary: wasm
			mainScriptUrlOrBlob: script
			pty: slave
			arguments: [
				'-nodefaults', '-display', 'none', '-serial', 'stdio', '-M', 'pc'
				'-m', '256M', '-accel', 'tcg', '-nic', 'none', '-no-reboot'
				'-L', '/firmware', '-kernel', '/vmlinuz', '-initrd', '/initramfs'
				'-append', 'console=ttyS0 rdinit=/init quiet'
			]
			preRun: [
				do(module)
					const fs = module.FS
					fs.mkdir('/firmware')
					for [name, first, last] of roms
						fs.writeFile('/firmware/' + name, new Uint8Array(firmware, first, last - first))
					fs.writeFile('/vmlinuz', new Uint8Array(kernel))
					fs.writeFile('/initramfs', new Uint8Array(initrd))
			]
			onAbort: do(reason)
				status.textContent = "The emulator stopped: {reason}"
				runExample.disabled = yes
		})

		const poll = instance.TTY.stream_ops.poll
		instance.TTY.stream_ops.poll = do(stream, timeout)
			if !slave.readable
				return slave.writable ? 4 : 0
			poll.call(this, stream, timeout)

		terminal.onWriteParsed do
			const buffer = terminal.buffer.active
			const line = buffer.getLine(buffer.baseY + buffer.cursorY)?.translateToString!
			if line and line.trimEnd!.endsWith('$') and runExample.hidden
				runExample.hidden = no
				status.textContent = 'Shell ready. Type a command or run the mount example.'

		runExample.addEventListener('click') do
			const commands = document.querySelector('#theseus-mount-commands').textContent.trim!.split("\n")
			terminal.input(commands.join(' && ') + "\r", yes)
			terminal.focus!
	catch error
		status.textContent = error.message || String(error)
		runExample.disabled = yes

start.addEventListener('click', boot)
reset.addEventListener('click') do globalThis.location.reload!

# The homepage boot link opens the console directly. Ordinary project visits
# still wait for the Start button before fetching the guest.
if new URL(globalThis.location.href).searchParams.get('boot') == '1'
	boot!
