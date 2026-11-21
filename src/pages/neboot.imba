export const title = 'neboot · Cascadia’s UEFI boot menu · Nelua at spacegho.st'
export const description = 'Boot Cascadia from loose files with neboot, an x86-64 UEFI application written in Nelua. See how necc and nelinker build it and what ran under OVMF.'

export def body
	<div className="page-content">
		<section className="hero">
			<p className="eyebrow"><a href="/nelua/#workshop"> 'Workshop'
			<h1> 'neboot'
			<p className="lead"> 'A UEFI boot menu written in Nelua. It starts Cascadia with Theseus Init or OpenRC recovery from the same kernel and initramfs. A third entry starts another EFI application.'
			<div className="actions">
				<a className="button" href="#run"> 'Boot in QEMU'
				<a className="text-link" href="#ovmf"> 'See the OVMF results'
		<h2 className="section" id="run"> 'Boot in QEMU'
		<p>
			'On an x86-64 host with the Cascadia launcher, install '
			<code> 'tools/neboot-live'
			' from the neboot repository on your PATH. The build needs the Nelua fork, necc and its staged SDK, nelinker, make, Python 3, xorriso, sfdisk and mtools. QEMU uses x86-64 OVMF firmware.'
		<pre><code> 'cascadia-live --uefi'
		<p> 'The launcher fetches neboot, prepares the latest Cascadia image, extracts the kernel and initramfs, and stages a temporary EFI disk as the user who runs it. At the serial menu, choose a key.'
		<ul>
			<li>
				<kbd> '1'
				' boots Cascadia with '
				<a href="/nelua/init/"> 'Theseus Init'
				' as PID 1.'
			<li>
				<kbd> '2'
				' boots Cascadia with OpenRC as PID 1 for recovery.'
			<li>
				<kbd> '3'
				' runs the second EFI application. Control returns to the menu when it exits or the file is missing.'
			<li>
				<kbd> 'Q'
				' returns to firmware.'
		<p><a href="https://github.com/Spaceghost/neboot"> 'Source and setup instructions on GitHub (repository access required)'
		<h2 className="section" id="build"> 'From Nelua to BOOTX64.EFI'
		<ol>
			<li>
				<a href="/nelua/compiler/#freestanding"> 'The Nelua fork'
				' emits freestanding C. Nelua records describe the firmware tables. Both the exported entry point and the function types stored in protocol records carry '
				<code> 'ms_abi'
				', so the convention survives an indirect call through a record field.'
			<li>
				<a href="/nelua/necc/#uefi"> 'necc'
				' compiles the generated C to x86-64 ELF objects using its native backend. The SDK supplies TinyCC for preprocessing and assembly.'
			<li>
				<a href="/nelua/nelinker/#uefi"> 'nelinker'
				' reads those objects and writes a PE32+ EFI application. Its base relocation table tells the firmware which absolute addresses to adjust if the image moves.'
		<p>
			'For example, the console’s write function has type '
			<code> 'function<ms_abi>(pointer, *uint16): usize'
			'. Calling it passes the console and a pointer to UTF-16 text back to firmware.'
		<p>
			'Both Linux entries start the EFI stub in '
			<code> '/boot/vmlinuz'
			' on the EFI System Partition and pass '
			<code> '/boot/initramfs'
			' in the kernel’s load options. The chainload entry starts '
			<code> '/EFI/TOOLS/second.efi'
			' from the same partition.'
		<h2 className="section" id="ovmf"> 'What ran under OVMF'
		<p>
			'On '
			<time html:datetime="2026-11-21"> '21 November 2026'
			', x86-64 QEMU with KVM and OVMF booted the image with Secure Boot disabled. The loader requested base '
			<code> '0x100000000'
			'. Firmware placed it at '
			<code> '0x3e2fb000'
			' in both runs.'
		<ul>
			<li>
				'With the child application present, it printed a message and returned to the menu. Selecting Theseus then booted Linux with '
				<code> 'theseus-init'
				' as PID 1. An HTTPS request from the guest returned 200.'
			<li>
				'With the child file missing, the menu reported '
				<code> 'EFI_NOT_FOUND'
				' and appeared again. Selecting OpenRC recovery booted Linux with '
				<code> 'openrc-init'
				' as PID 1.'
		<p>
			'A separate calling-convention test used a GCC-built firmware shim to call the Nelua entry point. The entry point called the shim’s console function through a protocol pointer and returned 42 to the caller.'
		<p><a href="/nelua/neboot/ovmf-proof.txt"> 'Read the console and ABI test excerpts (plain text)'
