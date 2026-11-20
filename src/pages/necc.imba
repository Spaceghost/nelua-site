export const title = 'necc · Native compiler driver · Nelua at spacegho.st'
export const description = 'Build C and Nelua programs for x86-64 Linux against standalone Nelibc, or run Lua with the necc compiler driver.'

export def body
	<div className="page-content">
		<section className="hero">
			<h1> 'necc'
			<p className="lead"> 'A compiler driver for x86-64 Linux. Use it to build C and Nelua programs against standalone Nelibc or run Lua from the same toolchain.'
		<h2 className="section"> 'Compile a program'
		<p>
			'These commands assume the staged SDK is installed at the distro default or selected with '
			<code> 'NECC_SYSROOT'
			'.'
		<pre>
			<code> "export NECC_SYSROOT=/path/to/sdk\nprintf '%s\\n' 'int main(void) \{ return 0; }' > hello.c\nnecc hello.c -o hello\n./hello\n\nprintf '%s\\n' \"print 'hello from Nelua'\" > hello.nelua\nnecc hello.nelua -o hello-nelua\n./hello-nelua\n\nnecc --lua -e 'print(_VERSION)'"
		<p> 'For a multi-file link, pass source files, object files and static archives together. Put archives after the objects that use them. Use -c to keep the object file from a single input.'
		<h2 className="section"> 'Choose a Nelua compilation path'
		<ul>
			<li>
				<code> 'necc program.nelua'
				' uses the full Nelua frontend and TinyCC as its C backend.'
			<li>
				<code> 'necc --native program.nelua'
				' sends the full frontend’s generated C through necc’s native C frontend. This path requires the program’s generated C to fit the supported subset.'
			<li>
				<code> 'necc --direct program.nelua'
				' selects the self-hosted Nelua subset frontend and the native C backend.'
		<p> 'The native C frontend emits System V x86-64 assembly. TinyCC in the SDK supplies preprocessing, assembly and static linking against Nelibc.'
		<h2 className="section"> 'Build the distro'
		<p>
			<a href="/nelua/nebuild/"> 'nebuild'
			' runs the build graph that uses necc to compile Nebox and package the Theseus boot image.'
		<div className="actions">
			<a className="button" href="https://github.com/Spaceghost/nebox#build-runner-for-the-distro-bootstrap"> 'Bootstrap instructions'
			' '
			<a className="button button-ghost" href="/nelua/compiler/"> 'Full Nelua compiler'
