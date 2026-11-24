export const title = 'nebox · Unix applets in Nelua · spacegho.st/nelua'
export const description = 'Nebox is a native Nelua userland. Browse its 138 standalone applets, try its shell, and check command coverage against BusyBox and Toybox.'

const groups = [
	{ range: '[ – C', names: '[ arch awk b2sum base32 base64 basenc basename cat chgrp chmod chown chroot cksum clear cmp comm cp csplit cut' }
	{ range: 'D – G', names: 'date dd df diff dir dircolors dirname dnsdomainname domainname du echo egrep env expand expr factor false fgrep find fmt fold free fsync grep groups gunzip gzip' }
	{ range: 'H – M', names: 'hd head hexdump hostid hostname id install join kill link ln logname ls lsmod mcookie md5sum mkdir mkfifo mknod mktemp mount mv' }
	{ range: 'N – R', names: 'nice nisdomainname nl nohup nproc nsh od paste patch pathchk pidof pinky printenv printf pwd pwdx readlink realpath rev rm rmdir' }
	{ range: 'S – T', names: 'sed seq setsid sh sha1sum sha224sum sha256sum sha384sum sha512sum shuf sleep sort split stat strings sum sync tac tail tar tee test timeout touch tr true truncate tsort tty ttysize' }
	{ range: 'U – Z', names: 'umount uname unexpand uniq unlink uptime users usleep uuidgen vdir wc which who whoami xargs yes ypdomainname zcat' }
]

export def body
	<div className="nebox-guide">
		<header className="ng-hero">
			<div>
				<p className="ng-crumb">
					<a href="/nelua/#core"> 'Core'
					<span aria-hidden="true"> ' / '
					'Userland'
				<h1> 'nebox'
				<p className="ng-intro"> 'A Unix toolbox written in Nelua.'
				<p className="ng-deck">
					'One static x86-64 binary carries 138 executable applets, including a POSIX shell. Pass a command to '
					<code> 'nebox'
					' or run it through a link named after the applet.'
				<nav className="ng-actions" aria-label="Explore Nebox">
					<a className="button" href="#applets"> 'Browse applets'
					<a href="#applet-coverage"> 'Check coverage'
			<figure className="ng-terminal">
				<figcaption>
					<span> 'Shell session'
					<span> 'x86-64'
				<pre>
					<code>
						<span className="ng-command"> "$ nebox --list | nebox wc -l\n"
						<span className="ng-output"> "138\n\n"
						<span className="ng-command"> "$ nebox sh -c 'command -v cd'\n"
						<span className="ng-output"> "cd"
		<section className="ng-section ng-coverage" aria-labelledby="applet-coverage">
			<div className="ng-section-head">
				<h2 id="applet-coverage"> 'BusyBox and Toybox coverage'
				<p className="ng-revision">
					<time datetime="2026-11-21"> 'Verified 2026-11-21'
					' · '
					<code> 'b948bce'
			<div className="ng-meter-panel">
				<div className="ng-reading">
					<div className="ng-number">
						<strong> '148'
						<span> ' / 524'
					<p> 'upstream command names covered'
				<div className="ng-breakdown">
					<meter min="0" max="524" value="148" aria-label="Upstream command names covered"> '148 of 524'
					<dl>
						<div>
							<dt> 'Executables'
							<dd> '126'
						<div>
							<dt> 'Shell builtins'
							<dd> '22'
						<div>
							<dt> 'Still missing'
							<dd> '376'
			<div className="ng-coverage-note">
				<p>
					'The catalog combines BusyBox 1.38.0 and Toybox 0.8.15. A name counts when Nebox supports each way upstream invokes it. The check reads '
					<code> '--list'
					' for executables and uses '
					<code> 'command -v'
					' inside the Nebox shell with external commands off its search path.'
				<div className="ng-links">
					<a href="/nelua/nebox/applet-coverage/"> 'Browse the full command table'
					<a href="/nelua/nebox/applet-coverage.txt"> 'Plain text'
		<section className="ng-section" aria-labelledby="applets">
			<div className="ng-section-head">
				<h2 id="applets"> 'Standalone applets'
				<code className="ng-invocation"> 'nebox --list'
			<p className="ng-copy">
				'The standalone build lists 138 commands, including 12 outside the two upstream catalogs. Use '
				<code> 'nebox --install [-s] DIR'
				' to create a link for each applet.'
			<div className="ng-directory">
				for group in groups
					<div className="ng-group">
						<h3> group.range
						<ul className="ng-names">
							for name in group.names.split(' ')
								<li> name
			<div className="ng-footnotes">
				<p>
					<strong> 'Added in this build. '
					'clear, egrep, fgrep, fsync, lsmod, mcookie, pidof, pwdx, ttysize, usleep and uuidgen.'
				<p>
					'The optional '
					<a href="/nelua/init/"> 'Theseus Init'
					' build adds '
					<code> 'init'
					' for a total of 139. '
					<a href="/cascadia/#system"> 'See what ships in Cascadia.'
		<section className="ng-section" aria-labelledby="compatibility">
			<h2 id="compatibility"> 'Using the toolbox'
			<div className="ng-features">
				<article>
					<h3> 'Shell and job control'
					<p>
						'Start an interactive shell with '
						<code> 'nebox sh -i'
						'. It supports editable history, tab completion, pipelines and background jobs. '
						<a href="/nelua/nebox/nsh/"> 'nsh'
						' adds a colored prompt and XDG history and configuration files.'
				<article>
					<h3> 'Text and files'
					<p>
						'Search with '
						<code> 'grep'
						', edit streams with '
						<code> 'sed'
						' and process records with '
						<code> 'awk'
						'. For larger jobs, sort can spill to disk, diff can compare directory trees, and tail can follow a rotating log.'
				<article>
					<h3> 'Archives and checksums'
					<p>
						'Create or extract a tar archive, compress a stream with gzip, or write decompressed data to standard output with zcat. Use '
						<code> 'sha256sum'
						' to verify a file.'
			<details className="ng-details" id="known-limits">
				<summary> 'Known limits'
				<p> 'Standalone locale data covers C, UTF-8 character handling and German collation. Some commands work byte by byte. Account enumeration reads the local databases. The grep -P option requires a build linked with static PCRE2.'
				<a href="https://github.com/Spaceghost/nebox#known-limits"> 'Applet compatibility notes'
		<section className="ng-section" aria-labelledby="build">
			<h2 id="build"> 'Build and test'
			<div className="ng-build">
				<div>
					<p>
						'Nebox links against '
						<a href="/nelua/nelibc/"> 'nelibc’s standalone archive'
						'. The conformance suite checks command output, exit status and changes to the filesystem. The coverage check tests which commands can be invoked.'
					<div className="ng-links">
						<a href="https://github.com/Spaceghost/nebox"> 'Nebox repository'
						<a href="https://github.com/Spaceghost/nebox/blob/master/tests/run.sh"> 'Conformance suite'
				<pre>
					<code> "git clone https://github.com/Spaceghost/nelibc\nmake -C nelibc lib-standalone-zig\ngit clone https://github.com/Spaceghost/nebox\nmake -C nebox NELIBC=../nelibc\nmake -C nebox NELIBC=../nelibc test"

			<p>
				'A static AArch64 prototype built in Fedora Incus and ran echo, wc, and printf under QEMU. Full applet conformance and runtime coverage remain in progress. '
				<a href="/nelua/nelibc/#linux-arm64"> 'See the AArch64 runtime tests.'

		<section className="ng-section" aria-labelledby="line-count">
			<h2 id="line-count"> 'Counting lines in Nelibc source'
			<p> '22 November 2026 · median elapsed milliseconds across 15 measured rounds on an i5-10400. Each process read the same 1,965,199-byte file. The line-only path now counts newline bytes directly.'
			<div className="table-wrap">
				<table>
					<thead>
						<tr>
							<th> 'Options'
							<th> 'Previous Nebox (ms)'
							<th> 'Updated Nebox (ms)'
							<th> 'GNU wc 9.1 (ms)'
					<tbody>
						<tr>
							<th scope="row"> '-l'
							<td> '5.031'
							<td> '1.644'
							<td> '1.045'
						<tr>
							<th scope="row"> '-lc'
							<td> '4.887'
							<td> '1.697'
							<td> '1.115'
						<tr>
							<th scope="row"> '-w'
							<td> '5.209'
							<td> '4.398'
							<td> '10.254'
			<div className="ng-links">
				<a href="/nelua/assets/core-shootout.zip"> 'Individual timings and counts (ZIP)'
				<a href="/nelua/assets/ecosystem-20261121/summary.csv"> '21 November quartiles and ranges'
				<a href="/nelua/assets/ecosystem-20261121/reproduce.txt"> 'Builds and reproduction'

export def footerLinks
	<div className="footer-links">
		<a href="https://github.com/Spaceghost/nebox"> 'Spaceghost/nebox'
