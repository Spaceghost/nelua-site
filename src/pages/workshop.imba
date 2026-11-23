import { opcodeNames } from '../showcase-files.mjs'
import { readFileSync } from 'node:fs'
import { highlight } from '../example-code.mjs'
export const title = 'The example workbench · Nelua'
export const description = 'Encode a Drift instruction, allocate WebAssembly memory, and run Nelua programs in the browser.'

def sourceView file
	<details>
		<summary> 'Show generated C'
		<pre>
			<code innerHTML=highlight(readFileSync('src/content/showcase/' + file + '.c','utf8').trimEnd())>

export def body
	<div className="workbench">
		<section className="hero">
			<h1> 'The example workbench'
			<p className="tagline"> 'Change the operands, watch memory fill, or send a string through C. Each experiment runs its compiled code in your browser.'
			<p className="workshop-jump">
				<a href="#assembler"> 'Instruction encoder'
				<a href="#arena"> 'Memory arena'
				<a href="#console-title"> 'Console'
			<div className="actions">
				<a href="/nelua/init/?boot=1#browser-demo"> 'Boot Theseus'
				<a href="/nelua/examples/life/"> 'Play Game of Life'
		<section id="assembler">
			<p className="eyebrow"> 'Drift · instruction encoding'
			<h2> 'Build an instruction word'
			<p> 'Pick an opcode and its three register fields. Nelua resolves the opcode in WebAssembly and calls Bend-generated JavaScript to pack the first four bytes of a Drift instruction.'
			<fieldset id="registers" html:disabled="">
				<legend> 'Instruction fields'
				<label> 'Opcode '
					<select id="op">
						for name, i in opcodeNames
							<option value=i html:selected=(name == 'ADD' ? '' : null)> name
				for id, index in ['a','b','c']
					<label> id.toUpperCase()
						<select id=id>
							for value in [0...16]
								<option value=value html:selected=(value == index + 1 ? '' : null)> value
			<p className="readout">
				<span> 'Instruction bytes'
				<output id="encoded" html:aria-live="polite"> 'Loading…'
			sourceView('assembler')
			<details>
				<summary> 'Follow the Bend build'
				<p> 'The encoder below uses the same compile-web.sh pipeline as Game of Life.'
				for source in [{label: 'Nelua encoder', path: 'examples/workshop/opcode.nelua'}, {label: 'Lowered Bend', path: 'public/nelua/examples/workshop/rule.bend'}, {label: 'Bend-generated JavaScript', path: 'public/nelua/examples/workshop/rule.mjs'}]
					<details>
						<summary> source.label
						<pre><code innerHTML=highlight(readFileSync(source.path,'utf8').trimEnd())>
		<section id="arena">
			<p className="eyebrow"> 'Melodica · WebAssembly memory'
			<h2> 'Fill the arena'
			<p> 'Ask the extension’s allocator for 13 bytes. Its pointer advances by 16 because allocations align to eight-byte boundaries.'
			<fieldset id="allocator" html:disabled="">
				<legend> 'Allocation request'
				<label for="bytes"> 'Bytes'
				<input id="bytes" type="number" min="0" max="262144" step="1" value="13" html:required="">
				<button id="allocate" type="button" className="button"> 'Allocate'
				<button id="clear-arena" type="button"> 'Reset'
			<progress id="capacity" max="262144" value="0" aria-label="Used arena memory">
			<p id="usage">
			<p id="address" html:role="status"> 'No allocations yet.'
			sourceView('arena')
		<section aria-labelledby="console-title">
			<p className="eyebrow"> 'C interop & compile-time evaluation'
			<h2 id="console-title"> 'Run the language examples'
			<div className="grid">
				for demo in [{name: 'c-call', title: 'Call puts from Nelua'}, {name: 'comptime', title: 'Print a compile-time constant'}, {name: 'point', title: 'Move a typed point'}]
					<article id=demo.name>
						<h3> demo.title
						<pre><code innerHTML=highlight(readFileSync('public/nelua/examples/' + demo.name + '.nelua','utf8').trimEnd())>
						<button id=('run-' + demo.name) type="button" html:disabled=""> 'Run program'
						<pre className="console"><samp id=('stdout-' + demo.name) html:role="status"> 'Ready'
						sourceView(demo.name)
		<p className="upstream-links">
			<a href="/nelua/examples/workshop/NOTICES.txt"> 'Project credits and licenses'
		<noscript> 'Enable JavaScript to run the experiments. The source and generated C are available below each example.'
