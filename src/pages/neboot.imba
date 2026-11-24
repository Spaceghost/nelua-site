export const title = 'neboot · Cascadia’s UEFI boot menu · Nelua at spacegho.st'
export const description = 'Neboot is a UEFI boot menu written in Nelua. Boot Cascadia on x86-64 or build and test the AArch64 menu and chainloader.'

export def body
	<div className="boot-lab boot-lab-neboot">
		<section className="boot-lab-hero" aria-labelledby="boot-title">
			<div className="boot-lab-intro">
				<p className="boot-lab-kicker"> 'Core / UEFI'
				<h1 id="boot-title"> 'neboot'
				<p className="boot-lab-lead"> 'A boot menu before Linux.'
				<p> 'A UEFI application written in Nelua. Start Cascadia with Theseus Init, choose OpenRC recovery, or launch a second EFI application from the same disk.'
				<div className="boot-lab-actions">
					<a className="button boot-lab-primary" href="#run"> 'Run it in QEMU'
					<a className="boot-lab-link" href="#browser-boot"> 'See the boot proof'
			<figure className="boot-lab-figure">
				<div className="boot-lab-screenhead"><span> 'From the firmware'
				<a className="boot-lab-image" href="./browser-proof/native-firmware.png" aria-label="Open the full native firmware capture">
					<img src="/nelua/neboot/browser-proof/native-firmware.png" width="1280" height="800" decoding="async" alt="Cascadia Core EFI menu displayed by neboot in native QEMU with OVMF">
				<figcaption> 'Neboot menu · native QEMU and OVMF capture'
		<nav className="boot-lab-nav" aria-label="neboot project links">
			<a href="#build"> 'How neboot builds'
			<a href="#ovmf"> 'Native OVMF results'
			<a href="#aarch64"> 'AArch64 firmware'
			<a href="/nelua/init/"> 'Meet Theseus Init'
		<section className="boot-lab-proof" aria-labelledby="browser-boot">
			<div>
				<p className="boot-lab-label"> 'Recorded test · native QEMU'
				<h2 className="section" id="browser-boot"> 'From firmware to a shell'
				<p> 'OVMF started neboot from an EFI disk. The menu launched the second EFI application, then booted Linux to a working Theseus/Nebox shell. The native capture above is the guest’s virtual VGA output.'
			<div className="boot-lab-notes">
				<h3> 'Browser prototype'
				<p> 'The browser build uses QEMU Wasm with the same EFI disk, not direct Linux boot. An end-to-end browser boot is not verified, so there is no browser launch button yet.'
				<p className="boot-lab-source-links">
					<a href="./browser-proof/native-serial.txt"> 'Read native serial evidence'
					<a href="./browser-proof/provenance.txt"> 'See source pins and hashes'

		<h2 className="section" id="efi-boot-time"> 'Time through the Core boot menu'
		<p> 'On 22 November 2026 four QEMU 10.2.2 TCG boots on an i7-11700F reached the Core menu in a median 1.35 s. Selecting the first entry took 4.00 s to reach the marker before StartImage. The median from that marker to a shell command identifying Theseus as PID 1 was 28.30 s. Each run started with fresh EFI variables and powered off successfully.'
		<p> 'This disk was rebuilt with neboot b8c56a8, necc 7ed048c, nelinker a349c2a, the core-dev-2026.11.20 release kernel and gzip initramfs. The four handoff-to-command intervals varied substantially on this host.'
		<p className="upstream-links">
			<a href="/nelua/assets/core-shootout.zip"> 'Four boot timings (ZIP)'
			<a href="/nelua/assets/ecosystem-20261121/reproduce.txt"> 'Original 21 November firmware and replay procedure'
		<h2 className="section" id="aarch64"> 'AArch64 firmware'
		<p> 'Neboot builds BOOTAA64.EFI and its child application with Nelua and Clang. The firmware test passed with lld-link and with Nelinker. In Fedora Incus, QEMU TCG with AArch64 EDK2 relocated the menu, showed the missing-kernel diagnostic, and chainloaded the child before returning to the menu.'
		<p> 'On 24 November 2026, Neboot also booted Fedora’s 7.3.4-200.fc44.aarch64 EFI-stub kernel. Both linker builds reached a minimal test initramfs running as PID 1 and powered off cleanly. The ARM Cascadia and Theseus boot path still needs an integration test.'
		<div className="actions">
			<a className="button" href="/nelua/neboot/neboot-aarch64-nelinker-23691f3.zip"> 'Download the Nelinker EFI build'
			<a href="/nelua/neboot/neboot-aarch64-09596e2.zip"> 'Download the lld-link EFI build'
			<a href="https://github.com/Spaceghost/neboot/tree/23691f3#aarch64-uefi"> 'Fedora Incus build and Linux handoff tests'
		<h2 className="section" id="run"> 'Boot in QEMU'
		<p>
			'In the '
			<a href="https://github.com/Spaceghost/neboot"> 'neboot checkout'
			' (repository access required), put the Nelua fork, necc and nelinker on your PATH. If you installed the necc SDK outside its default location, set '
			<code> 'NECC_SYSROOT'
			' to the SDK directory.'
		<p> 'Stage an x86-64 EFI-stub kernel and its matching Cascadia initramfs. Replace the example paths with your local files.'
		<pre><code> 'make stage KERNEL=/path/to/vmlinuz INITRD=/path/to/initramfs'
		<details>
			<summary> 'Starting from a Cascadia ISO'
			<p> 'With xorriso installed, this command extracts both boot files from the same verified local ISO and stages them in build/esp.'
			<pre><code> 'make stage-iso ISO=/path/to/cascadia-native-x86_64.iso'
		<p> 'Open the serial menu. The script uses Python 3, sfdisk and mtools to prepare a temporary disk, then boots it with QEMU and x86-64 OVMF.'
		<pre><code> 'python3 tests/smoke-ovmf.py --esp build/esp --interactive'
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
		<p>
			'To exit QEMU from the menu or a running guest, press '
			<kbd> 'Ctrl+A'
			', then '
			<kbd> 'X'
			'.'
		<details>
			<summary> 'Select a firmware pair or use software emulation'
			<p>
				'If the script cannot find your firmware, set '
				<code> 'OVMF_CODE'
				' and '
				<code> 'OVMF_VARS'
				' to a matching x86-64 OVMF pair with Secure Boot disabled. The test copies the variables file for each boot. QEMU uses KVM when your account can access /dev/kvm and software emulation otherwise. Set '
				<code> 'QEMU_ACCEL=tcg'
				' to select software emulation explicitly.'
		<h2 className="section" id="verify"> 'Repeat the two-boot test'
		<p> 'With the boot files staged, run the automated check from the same checkout. It tests the child application, repeats with the child missing, and checks PID 1 after each Linux boot. The Theseus guest also makes an HTTPS request to example.com.'
		<pre><code> 'python3 tests/smoke-ovmf.py --esp build/esp --logs build/logs --check-internet'
		<p>
			'Compare the PASS lines with the '
			<a href="#ovmf"> 'recorded OVMF results'
			'. The serial transcripts are saved in '
			<code> 'build/logs/theseus-chainload.log'
			' and '
			<code> 'build/logs/openrc-missing.log'
			'.'
		<p> 'If HTTPS fails, the test reports the guest’s curl exit code, HTTP status and serial log path.'
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
			'. On the first host, firmware placed it at '
			<code> '0x3e2fb000'
			' for both menu entries. A fresh build on a second host produced the same EFI binary. There, OVMF placed it at '
			<code> '0x3e10c000'
			'. The test compares the observed address to the preferred base on each boot.'
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
