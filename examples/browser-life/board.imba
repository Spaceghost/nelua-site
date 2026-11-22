const board = document.querySelector('#life-board')
const step = document.querySelector('#life-step')
const play = document.querySelector('#life-play')
const pattern = document.querySelector('#life-pattern')
let timer = null
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
	board.setAttribute('aria-label', "Game of Life {pattern.value} at generation {generation}")
	status.textContent = "Generation {generation}"

def pause
	if timer != null
		clearInterval(timer)
	timer = null
	play.textContent = 'Play'

def seed
	pause!
	rows.fill(0)
	if pattern.value == 'blinker'
		rows[7] = 7 << 6
	elif pattern.value == 'block'
		rows[7] = rows[8] = 3 << 7
	else
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
		def advance
			const next = new Uint16Array(16)
			for y in [0...16]
				next[y] = wasm.instance.exports.next_row(rows[(y + 15) % 16], rows[y], rows[(y + 1) % 16])
			rows = next
			generation += 1
			draw!
		step.addEventListener('click') do
			pause!
			advance!
		play.addEventListener('click') do
			if timer == null
				timer = setInterval(advance, 240)
				play.textContent = 'Pause'
			else
				pause!
		document.addEventListener('visibilitychange') do
			pause! if document.hidden
		pattern.addEventListener('change', seed)
		play.disabled = false
		pattern.disabled = false
		reset.addEventListener('click', seed)
		reset.disabled = false
		step.disabled = false
		seed!
	catch error
		status.textContent = "Could not load the simulation: {error.message}"

load!
