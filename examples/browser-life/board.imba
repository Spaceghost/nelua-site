const board = document.querySelector('#life-board')
const step = document.querySelector('#life-step')
const play = document.querySelector('#life-play')
const pattern = document.querySelector('#life-pattern')
const reroll = document.querySelector('#life-reroll')
const speed = document.querySelector('#life-speed')
const counter = document.querySelector('#life-generation')
let timer = null
const reset = document.querySelector('#life-reset')
const status = document.querySelector('#life-status')
const context = board.getContext('2d')
let generation = 0
const initial = new Uint16Array(16)
let rows = new Uint16Array(16)

def draw
	context.fillStyle = '#172339'
	context.fillRect(0, 0, 320, 320)
	for y in [0...16]
		for x in [0...16]
			context.fillStyle = (rows[y] & (1 << x)) ? '#a5e2cc' : '#283b54'
			context.fillRect(x * 20 + 1, y * 20 + 1, 18, 18)
	board.setAttribute('aria-label', "Game of Life {pattern.value} at generation {generation}")
	counter.textContent = "Generation {generation}"

def pause
	if timer != null
		clearInterval(timer)
	timer = null
	play.textContent = 'Play'
	status.textContent = 'Paused'

def restart
	pause!
	rows.set(initial)
	generation = 0
	draw!

def seed
	initial.fill(0)
	reroll.hidden = pattern.value != 'random'
	if pattern.value == 'random'
		crypto.getRandomValues(initial)
	elif pattern.value == 'blinker'
		initial[7] = 7 << 6
	elif pattern.value == 'beacon'
		initial[6] = initial[7] = 3 << 5
		initial[8] = initial[9] = 3 << 7
	elif pattern.value == 'block'
		initial[7] = initial[8] = 3 << 7
	else
		initial[4] = 1 << 6
		initial[5] = 1 << 7
		initial[6] = 7 << 5
	restart!

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
		def start
			clearInterval(timer)
			timer = setInterval(advance, Number(speed.value))
			play.textContent = 'Pause'
			status.textContent = 'Playing'
		speed.addEventListener('change') do
			start! if timer != null
		speed.disabled = false
		step.addEventListener('click') do
			pause!
			advance!
		play.addEventListener('click') do
			if timer == null
				start!
			else
				pause!
		document.addEventListener('visibilitychange') do
			pause! if document.hidden
		pattern.addEventListener('change', seed)
		play.disabled = false
		pattern.disabled = false
		reroll.addEventListener('click', seed)
		reset.addEventListener('click', restart)
		reset.disabled = false
		step.disabled = false
		seed!
	catch error
		status.textContent = "Could not load the simulation: {error.message}"

load!
