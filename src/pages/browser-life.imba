import { readFileSync } from 'node:fs'
import { highlight } from '../example-code.mjs'
export const title = 'Game of Life · Imba, Bend and Nelua'
export const description = 'Play Conway’s Game of Life in a browser running a Bend-generated JavaScript rule inside a Nelua WebAssembly simulation.'

def listing label, path
	<details>
		<summary> label
		<pre>
			<code innerHTML=highlight(readFileSync(path, 'utf8').trimEnd())>

export def body
	<section className="hero">
		<p className="eyebrow"> 'Imba · Bend · Nelua'
		<h1> 'Conway’s Game of Life'
		<p className="tagline"> 'Press Play to follow the glider. Every four generations it moves one square diagonally, wrapping around when it reaches an edge.'
	<div className="grid life-lab">
		<section>
			<canvas id="life-board" width="320" height="320" aria-label="Game of Life board"> 'A 16 by 16 Game of Life board.'
			<p className="life-readout">
				<span id="life-status" html:role="status"> 'Loading…'
				<span id="life-generation">
			<div className="actions">
				<button id="life-play" type="button" className="button" html:disabled=""> 'Play'
				<button id="life-step" type="button" className="button button-ghost" html:disabled=""> 'Step once'
				<button id="life-reset" type="button" className="button button-ghost" html:disabled=""> 'Restart pattern'
			<details className="life-settings">
				<summary> 'Pattern and playback speed'
				<label for="life-pattern"> 'Starting pattern'
				<select id="life-pattern" html:disabled="">
					<option value="glider"> 'Glider · travels (default)'
					<option value="blinker"> 'Blinker · flips direction'
					<option value="beacon"> 'Beacon · pulses'
					<option value="block"> 'Block · stays still'
				<label for="life-speed"> 'Playback speed'
				<select id="life-speed" html:disabled="">
					<option value="240"> 'Normal · 1× (default)'
					<option value="480"> 'Slow · 0.5×'
					<option value="120"> 'Fast · 2×'
					<option value="60"> 'Fastest · 4×'
				<p> 'Changing the pattern starts a fresh board. Change speed at any time.'
			<noscript> 'Enable JavaScript to play the simulation.'
		<section>
			<h2> 'One tick through the toolchain'
			<p> 'Imba controls playback and draws the grid. A Nelua WebAssembly function counts the neighbors. For each cell it calls a JavaScript function compiled by Bend to decide whether the cell lives.'
			<p> 'The survival rule starts as typed Nelua inside a file-local bendjs block. The extension reuses the fork’s Bend2 lowering pass. Open the artifacts below to follow the same rule through the build.'
			listing('Nelua source', 'examples/browser-life/life.nelua')
			listing('Lowered Bend', 'public/nelua/examples/life/rule.bend')
			listing('JavaScript emitted by Bend', 'public/nelua/examples/life/rule.mjs')
			listing('C emitted by Nelua for the WebAssembly guest', 'public/nelua/examples/life/life.c')
			listing('Imba interface', 'examples/browser-life/board.imba')
			<p>
				<a href="/nelua/examples/life/starter.tar.gz"> 'Download the project and build instructions'
