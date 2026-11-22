import { readFileSync } from 'node:fs'
import { highlight } from '../example-code.mjs'
export const title = 'Game of Life · Imba, Bend and Nelua'
export const description = 'Step a glider forward in a browser running a Bend-generated JavaScript rule inside a Nelua WebAssembly simulation.'

def listing label, path
	<details>
		<summary> label
		<pre>
			<code innerHTML=highlight(readFileSync(path, 'utf8').trimEnd())>

export def body
	<section className="hero">
		<p className="eyebrow"> 'Imba · Bend · Nelua'
		<h1> 'Follow a glider'
		<p className="tagline"> 'Five cells travel across a wrapping board. Step four generations and watch the pattern reappear one square down and to the right.'
	<div className="grid life-lab">
		<section>
			<label for="life-pattern"> 'Starting pattern '
			<select id="life-pattern" html:disabled="">
				<option value="glider"> 'Glider'
				<option value="blinker"> 'Blinker'
				<option value="block"> 'Still life'
			<canvas id="life-board" width="320" height="320" aria-label="Game of Life board"> 'A 16 by 16 Game of Life board.'
			<div className="actions">
				<button id="life-step" type="button" className="button" html:disabled=""> 'Step one generation'
				<button id="life-play" type="button" className="button button-ghost" html:disabled=""> 'Play'
				<button id="life-reset" type="button" className="button button-ghost" html:disabled=""> 'Reset'
			<p id="life-status" html:role="status"> 'Loading the simulation…'
			<noscript> 'Enable JavaScript to step the simulation.'
		<section>
			<h2> 'One tick through the toolchain'
			<p> 'Imba handles the button and draws the grid. A Nelua WebAssembly function counts the neighbors. For each cell it calls a JavaScript function compiled by Bend to decide whether the cell lives.'
			<p> 'The survival rule starts as typed Nelua inside a file-local bendjs block. The extension reuses the fork’s Bend2 lowering pass. Open the artifacts below to follow the same rule through the build.'
			listing('Nelua source', 'examples/browser-life/life.nelua')
			listing('Lowered Bend', 'public/nelua/examples/life/rule.bend')
			listing('JavaScript emitted by Bend', 'public/nelua/examples/life/rule.mjs')
			listing('C emitted by Nelua for the WebAssembly guest', 'public/nelua/examples/life/life.c')
			listing('Imba interface', 'examples/browser-life/board.imba')
			<p>
				<a href="/nelua/examples/life/starter.tar.gz"> 'Download the project and build instructions'
