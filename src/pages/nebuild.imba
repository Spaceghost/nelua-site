export const title = 'nebuild · Incremental build runner · Nelua at spacegho.st'
export const description = 'Run incremental and parallel builds from a build.ne dependency graph with Nebox’s standalone nebuild runner.'

export def body
	<div className="page-content">
		<section className="hero">
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
		<h2 className="section"> 'Build the runner from Nebox'
		<p><a href="https://github.com/Spaceghost/nebox/blob/master/tools/nebuild.nelua"> 'nebuild source in Nebox'
		<p> 'From a Nebox checkout with Nelua, Zig and the standalone Nelibc archive available, build and test the runner with the same toolchain used for Nebox.'
		<pre>
			<code> "make NELIBC=/path/to/nelibc nebuild\nmake NELIBC=/path/to/nelibc test-nebuild"
		<div className="actions">
			<a className="button" href="https://github.com/Spaceghost/nebox#build-runner-for-the-distro-bootstrap"> 'Nebox build documentation'
			' '
			<a className="button button-ghost" href="/nelua/necc/"> 'Compile with necc'
