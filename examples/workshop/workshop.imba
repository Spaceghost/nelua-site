import {runConsole} from './wasi.mjs'

def el id
	document.getElementById(id)

def getModule name
	const response = await fetch(name + '.wasm')
	throw new Error("HTTP {response.status} loading {name}") unless response.ok
	WebAssembly.compile(await response.arrayBuffer!)

def setupEncoder
	const url = new URL('rule.mjs', document.baseURI).href
	const [rules, mod] = await Promise.all([import(url), getModule('opcode')])
	const pack = do(op, a, b, c) rules.default.pack_word(op >>> 0, a >>> 0, b >>> 0, c >>> 0)
	const instance = await WebAssembly.instantiate(mod, {env: {pack_word: pack}})
	const inputs = ['op','a','b','c'].map(do(id) el(id))
	def render
		const [op, a, b, c] = inputs.map(do(input) Number(input.value))
		const word = instance.exports.encode(op, a, b, c)
		const bytes = [0, 8, 16, 24].map(do(shift) ((word >>> shift) & 255).toString(16).padStart(2,'0'))
		el('encoded').textContent = bytes.join(' ').toUpperCase!
	for input in inputs
		input.addEventListener('input', render)
	el('registers').disabled = false
	render!

def setupArena
	const instance = await WebAssembly.instantiate(await getModule('arena'), {})
	const arena = instance.exports
	const size = el('bytes')
	const meter = el('capacity')
	meter.max = arena.mx_arena_capacity!
	def used
		meter.value = arena.mx_arena_used!
		el('usage').textContent = "{meter.value.toLocaleString!} / {meter.max.toLocaleString!} bytes"
	el('allocate').addEventListener('click') do
		return unless size.reportValidity!
		const before = arena.mx_arena_used!
		const pointer = arena.mx_alloc(size.valueAsNumber)
		used!
		el('address').textContent = pointer ? "Reserved {meter.value - before} bytes at 0x{(pointer >>> 0).toString(16)}." : 'The arena is full for this request.'
	el('clear-arena').addEventListener('click') do
		arena.mx_reset!
		used!
		el('address').textContent = 'Arena reset.'
	el('allocator').disabled = false
	used!

def setupConsole name
	const button = el('run-' + name)
	const output = el('stdout-' + name)
	button.disabled = false
	button.addEventListener('click') do
		button.disabled = true
		try
			output.textContent = await runConsole(await getModule(name))
		catch error
			output.textContent = error.message
		finally
			button.disabled = false

setupEncoder!.catch(do(error) el('encoded').textContent = error.message)
setupArena!.catch(do(error) el('address').textContent = error.message)
setupConsole('c-call')
setupConsole('comptime')
setupConsole('point')
