export const title = 'Theseus init · Nelua at spacegho.st'
export const description = 'Theseus is a Linux service supervisor written in Nelua, with CUE service definitions, OpenRC compatibility, and an opt-in PID 1.'

export def body
	<div>
		<section className="hero">
			<h1> 'Theseus init'
			<p className="lead">
				'A Linux service supervisor written in Nelua. CUE describes services and their dependencies. Theseus starts them in order and waits for their readiness checks.'
			<div className="actions">
				<a className="button" href="https://github.com/Spaceghost/theseus-init"> 'Theseus repository'
				' '
				<a className="button button-ghost" href="https://github.com/Spaceghost/nebox#boot-with-theseus"> 'Boot Nebox in QEMU'
		<h2 className="section"> 'Supervise services'
		<p>
			'The userspace daemon runs foreground services and native targets. It tracks child processes with Linux pidfds, reaps adopted children, and applies each service’s restart policy. The OpenRC adapter runs installed Alpine service scripts through the system OpenRC runtime.'
		<pre>
			<code> "theseusd --target TARGET\nthe status of openrc postgresql"
		<h2 className="section"> 'Boot and rescue'
		<p>
			'Theseus has an opt-in native PID 1 for isolated Linux VM testing. It starts the supervisor and opens a console rescue shell if boot fails.'
		<p>
			'The '
			<a href="/nelua/nebox/"> 'Theseus-enabled Nebox build'
			' also provides an initramfs entry point. It mounts procfs and sysfs, starts an interactive shell on the boot console, and restarts the shell when it exits.'
