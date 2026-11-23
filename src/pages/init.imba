export const title = 'Theseus init · Nelua at spacegho.st'
export const description = 'Theseus is a Linux service supervisor written in Nelua, with CUE service definitions, OpenRC compatibility, and an opt-in PID 1.'

export def body
	<div>
		<section className="hero">
			<h1> 'Theseus init'
			<p className="lead">
				'A Linux service supervisor written in Nelua. CUE describes services and their dependencies. Theseus starts them in order and waits for their readiness checks.'
			<div className="actions">
				<a className="button" href="#browser-demo"> 'Try the browser demo'
				' '
				<a className="button button-ghost" href="https://github.com/Spaceghost/theseus-init"> 'Theseus repository'
				' '
				<a className="button button-ghost" href="https://github.com/Spaceghost/nebox#boot-with-theseus"> 'Boot Nebox in QEMU'
		<h2 className="section" id="core-boot-time"> 'Time to a working serial shell'
		<p> 'Theseus Init is a related project outside Nelua core. In the Cascadia Core developer image it starts the Nebox console. On 22 November 2026 five alternating pairs under QEMU 10.2.2 TCG took a median 6.27 s with the gzip release image and 10.13 s with the same cpio bytes encoded as legacy LZ4. The clock starts at process launch and stops when a shell command returns.'
		<p> 'On the i7-11700F, gzip ranged from 5.39 to 11.68 s and LZ4 from 7.97 to 28.75 s. The 21 November i7-9700K favored LZ4. The separate gzip control on this host took 5.80 s for a direct shell and 6.25 s with Theseus.'
		<p className="upstream-links">
			<a href="/nelua/assets/core-shootout.zip"> 'Boot samples (ZIP)'
			<a href="https://github.com/Spaceghost/cascadia/blob/3fa30c5703ef7801b9ebd327f29d359f903026eb/docs/CORE-DEVELOPER.md#faster-repeated-boots-under-software-emulation"> 'Boot commands and timing harness'
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

		<section aria-labelledby="browser-demo">
			<h2 id="browser-demo" className="section"> 'Boot Nebox in your browser'
			<p> 'Start a Linux VM with Theseus as PID 1. The guest runs locally in your browser and has no network connection.'
			<div className="actions">
				<button id="theseus-start" className="button" type="button"> 'Start Nebox'
				' '
				<button id="theseus-reset" className="button button-ghost" type="button" html:hidden=""> 'Reset demo'
			<p id="theseus-status" role="status" className="muted">
				'Starting the VM downloads about 30 MB. Wait for the shell prompt to appear.'
			<div id="theseus-console" html:hidden="">
				<div id="theseus-terminal" aria-label="Nebox serial console">
				<button id="theseus-example" className="button button-ghost" type="button" html:hidden=""> 'Run mount example'
			<noscript> 'Enable JavaScript to start the browser VM.'
			<p className="muted">
				'Emulation by '
				<a href="https://github.com/ktock/qemu-wasm"> 'QEMU Wasm'
				'. '
				<a href="/nelua/init/vm/NOTICES.txt"> 'Demo sources and licenses'
		<h2 className="section"> 'Working with mounts'
		<p> 'In the Nebox guest, use mount to attach filesystems and umount to detach them. The following example creates a temporary filesystem at the existing /mnt directory in the boot image.'
		<pre>
			<code id="theseus-mount-commands"> "/bin/nebox mount -o size=16m,mode=0755 tmpfs /mnt\n/bin/nebox mount -t tmpfs\n/bin/nebox umount /mnt"
		<p>
			'Use '
			<code> '/bin/nebox mount TARGET'
			' to look up a configured target in '
			<code> '/etc/fstab'
			'. '
			<code> '/bin/nebox mount -T FILE TARGET'
			' selects another table.'
