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
