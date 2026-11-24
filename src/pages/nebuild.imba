import { readFileSync } from 'node:fs'
export const title = 'nebuild · Incremental build runner · Nelua at spacegho.st'
export const description = 'Run incremental and parallel builds from a build.ne dependency graph with the standalone Nelua build runner.'

const nebuildPassRows = [
	["256 rules", "2.249", "0.611", "0.995", "1.352"]
	["2,048 rules", "17.041", "3.043", "2.783", "2.724"]
]

export def body
	<div className="page-content">
		<section className="hero">
			<p className="eyebrow"> 'Core · the build runner'
			<h1> 'nebuild'
			<p className="lead"> 'A small dependency runner written in Nelua. It builds the requested outputs from a build.ne file and skips recipes whose inputs and previous outputs still match.'
		<h2 className="section"> 'Write a build.ne file'
		<p>
			'Each '
			<code> 'build'
			' line names one output followed by its inputs. Start the recipe on the next line with a literal tab. The optional '
			<code> 'default'
			' line selects what to build when no target is supplied.'
		<pre>
			<code> "build out/hello hello.c\n\tnecc hello.c -o out/hello\ndefault out/hello"
		<p>
			'With necc on PATH and its SDK configured, create the output directory and run these commands from the directory containing '
			<code> 'build.ne'
			'.'
		<pre>
			<code> "mkdir -p out\nnebuild -j 2 build.ne\nnebuild build.ne out/hello"
		<h2 className="section"> 'What makes a recipe run again'
		<p> 'nebuild records the recipe, declared inputs and their metadata, and the last successful build of each generated input. An output rebuilds when it is missing or when one of those records changes. Declare headers, compiler binaries and configuration files as inputs when they affect the output.'
		<p> 'Recipes run through /bin/sh. Independent jobs can run in parallel. A lock serializes invocations that share the working directory.'
		<h2 className="section" id="benchmarks"> 'Checking an unchanged target'
		<p>
			'On '
			<time html:datetime="2026-11-22"> '22 November 2026'
			', nebuild checked one up-to-date target in a 2,048-rule manifest in 3.735 ms. The previous build took 22.931 ms. The parser now scans manifest bytes directly and prepares the recipe signature only for targets the runner visits.'
		<div className="table-wrap" role="region" aria-label="Median elapsed time in milliseconds" html:tabindex="0">
			<table>
				<thead>
					<tr>
						<th scope="col"> 'Manifest size'
						<th className="num" scope="col"> 'Before (ms)'
						<th className="num" scope="col"> 'nebuild (ms)'
						<th className="num" scope="col"> 'GNU make (ms)'
						<th className="num" scope="col"> 'Ninja (ms)'
				<tbody>
					for row in [['256 rules', '3.097', '0.788', '0.912', '2.464'], ['2,048 rules', '22.931', '3.735', '4.014', '3.884']]
						<tr>
							<th scope="row"> row[0]
							for value in row.slice(1)
								<td className="num"> value
		<p> 'Each median covers 31 warm runs on logical CPU 5 of an Intel Core i5-10400. Every rule copied the same source to a different output. Each invocation opened its manifest and checked one previously built output. The harness verified its contents and timestamp after every invocation. Clean builds and parallel recipe execution were outside this timing.'
		<details id="build-samples">
			<summary> '22 November samples for both manifest sizes'
			<pre> readFileSync('src/content/build-incremental.csv', 'utf8').trimEnd()
		<h3 id="incremental-repeat"> "Independent manifest timing"
		<p> "On 22 November 2026, twelve warm rounds repeated the unchanged-target check on logical CPU 7 of an i7-11700F. Every result retained the same output contents and timestamp."
		<div className="table-wrap">
			<table>
				<thead>
					<tr>
						<th scope="col"> "Graph"
						<th scope="col"> "0441e93 (ms)"
						<th scope="col"> "60d1200 (ms)"
						<th scope="col"> "GNU make (ms)"
						<th scope="col"> "Ninja (ms)"
				<tbody>
					for row in nebuildPassRows
						<tr>
							<th scope="row"> row[0]
							<td className="num"> row[1]
							<td className="num"> row[2]
							<td className="num"> row[3]
							<td className="num"> row[4]
		<p> "Reading the larger manifest cost about 0.32 ms more than Ninja on this host. This comparison covers a single requested target."
		<p className="upstream-links">
			<a href="/nelua/assets/core-shootout.zip"> "Manifest timing samples (ZIP)"
			<a href="/nelua/assets/ecosystem-20261121/summary.csv"> "21 November quartiles and observed ranges"
			<a href="/nelua/assets/ecosystem-20261121/reproduce.txt"> "Versions and reproduction"
		<p className="upstream-links">
			<a href="/nelua/assets/build-tools-20261121/incremental.csv"> '21 November individual times (CSV)'
			<a href="/nelua/assets/build-tools-20261121/method.txt"> 'Method and reproduction'
		<h2 className="section"> 'Build nebuild'
		<p> 'Build the standalone x86-64 runner with Nelua, Zig and the standalone Nelibc archive.'
		<pre>
			<code> "git clone https://github.com/Spaceghost/nebuild\ncd nebuild\nmake NELIBC=/path/to/nelibc\nmake NELIBC=/path/to/nelibc test\nmake NELIBC=/path/to/nelibc install PREFIX=\"$HOME/.local\""
		<p> 'For Linux AArch64 or x86-64 with a system C library, build the hosted runner with Nelua and GCC. The test target also needs Python.'
		<pre>
			<code> "make hosted NELUA=/path/to/nelua CC=gcc\nmake test-hosted NELUA=/path/to/nelua CC=gcc"
		<div className="actions">
			<a className="button" href="https://github.com/Spaceghost/nebuild"> 'nebuild repository'
			' '
			<a className="button button-ghost" href="/nelua/necc/"> 'Compile with necc'
