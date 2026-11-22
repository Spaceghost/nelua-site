const board = document.querySelector('#life-board')
const step = document.querySelector('#life-step')
const reset = document.querySelector('#life-reset')
const status = document.querySelector('#life-status')
const context = board.getContext('2d')
let generation = 0
let rows = new Uint16Array(16)

def draw
	context.fillStyle = '#172339'
	context.fillRect(0, 0, 320, 320)
	for y in [0...16]
		for x in [0...16]
			context.fillStyle = (rows[y] & (1 << x)) ? '#a5e2cc' : '#283b54'
			context.fillRect(x * 20 + 1, y * 20 + 1, 18, 18)
	board.setAttribute('aria-label', "Game of Life glider at generation {generation}")
	status.textContent = "Generation {generation}"

def seed
	rows.fill(0)
	rows[4] = 1 << 6
	rows[5] = 1 << 7
	rows[6] = 7 << 5
	generation = 0
	draw!

def load
	try
		const ruleURL = new URL('rule.mjs', document.baseURI).href
		const rules = await import(ruleURL)
		const response = await fetch('life.wasm')
		throw new Error("HTTP {response.status}") unless response.ok
		const survives = do(alive, neighbors) rules.default.survives(alive >>> 0, neighbors >>> 0)
		const wasm = await WebAssembly.instantiate(await response.arrayBuffer!, {env: {survives: survives}})
		step.addEventListener('click') do
			const next = new Uint16Array(16)
			for y in [0...16]
				next[y] = wasm.instance.exports.next_row(rows[(y + 15) % 16], rows[y], rows[(y + 1) % 16])
			rows = next
			generation += 1
			draw!
		reset.addEventListener('click', seed)
		reset.disabled = false
		step.disabled = false
		seed!
	catch error
		status.textContent = "Could not load the simulation: {error.message}"

load!
