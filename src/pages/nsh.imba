export const title = "nsh · the Nelua shell · spacegho.st/nelua"
export const description = "nsh is nebox's interactive POSIX shell, written in Nelua on nelibc: a line editor with history search and completion, error recovery, and the full POSIX command language checked against dash, in one static binary with no host libc."

export def body
	<div className="page-content">
		<section className="hero">
			<p className="eyebrow"> "nebox · the shell"
			<h1> "nsh"
			<p className="tagline"> "A POSIX shell to live in, written in Nelua all the way down to the C library."
			<p className="blurb">
				<code> "nsh"
				" is the interactive side of "
				<a html:href="/nelua/nebox/"> "nebox"
				"'s "
				<code> "sh"
				": the same POSIX command language, checked against dash case by case, with a line editor, history, completion and a prompt built for everyday use. It is one applet of a static x86-64 binary that links no host libc at all; everything under it, down to "
				<code> "tcgetattr"
				" and "
				<code> "setjmp"
				", is "
				<a html:href="/nelua/nelibc/"> "nelibc"
				"."
			<p className="stats">
				<span>
					<strong> "444"
					" POSIX cases against dash"
				<span>
					<strong> "24"
					" pseudo-terminal sessions"
				<span>
					<strong> "1,788,432 bytes"
					" for all 89 applets"
				<span>
					<strong> "nm -u"
					" empty"
				<span> "recorded 2026-11-07"
		<div className="page-details">
			<h2 className="section"> "A session"
			<p className="lead">
				"A replay of a real "
				<code> "nsh"
				" session, recorded on a pseudo-terminal from the build that the tests ran on (only the home directory's path is shortened to "
				<code> "/home/demo"
				"). Keys pressed are shown as chips."
			<div className="term" html:role="region" html:aria-label="Replay of an nsh session">
				<div className="term-bar">
					<span className="dot">
					<span className="dot">
					<span className="dot">
					<span className="title"> "nsh — /home/demo"
					<button html:type="button" html:id="replay"> "Replay"
				<pre className="term-body" html:id="screen" html:aria-live="off">
			<noscript>
				<p className="note"> "The replay needs JavaScript; the transcript is below."
			<h2 className="section"> "What it does"
			<div className="grid">
				<article className="card card-core">
					<h3> "The line editor"
					<p> "Its own editor, in Nelua: lines that wrap past the terminal width redraw correctly, the cursor moves by UTF-8 character, consecutive kills join into one entry as in readline, and pasted text arrives whole through bracketed paste instead of being run line by line."
				<article className="card card-core">
					<h3> "History"
					<p>
						"Every command, multi-line ones included, goes to "
						<code> "~/.local/state/nsh/history"
						" (or "
						<code> "$HISTFILE"
						") as it runs, so a crash loses nothing. Up and Down walk it; Ctrl-R searches it incrementally. A line equal to the one before, or starting with a space, is not kept."
				<article className="card card-core">
					<h3> "Completion"
					<p>
						"Tab completes commands in command position (built-ins, functions, aliases, reserved words and everything on "
						<code> "PATH"
						"), file names elsewhere (with "
						<code> "~"
						", directories ending in "
						<code> "/"
						", special characters escaped) and "
						<code> "$NAME"
						"s. A second Tab lists the candidates in columns."
				<article className="card">
					<h3> "Mistakes don't end the session"
					<p>
						"A syntax error, a failed expansion such as "
						<code> "$\{x?}"
						", or an error in a special built-in returns to the prompt with status 2, as POSIX requires of an interactive shell. Ctrl-C ends what is being typed or run; SIGTERM and SIGQUIT are ignored by the shell, never by its children."
				<article className="card">
					<h3> "Prompts that compute"
					<p>
						<code> "PS1"
						" gets parameter, command and arithmetic expansion before each prompt, then "
						<code> "!"
						" becomes the history number. The default shows the directory's name in colour, "
						<code> "~"
						" at home, and "
						<code> "#"
						" for root. "
						<code> "PS2"
						" marks continuation lines and here-documents."
				<article className="card card-core">
					<h3> "Job control"
					<p>
						"Every pipeline gets its own process group and the foreground one owns the terminal. Ctrl-Z stops it and hands the terminal back with the shell's own modes; "
						<code> "fg"
						" restores the job's modes and continues it, "
						<code> "bg"
						" lets it run behind you, and "
						<code> "jobs"
						", "
						<code> "kill %1"
						" and "
						<code> "wait %vim"
						" name jobs by number, prefix or substring. Finished background jobs are reported before the next prompt, and leaving with stopped jobs warns first."
				<article className="card">
					<h3> "The whole POSIX language"
					<p>
						"Pipelines, lists, subshells, functions, "
						<code> "case"
						" and loops, every redirection and here-document form, aliases, all parameter expansions, command substitution, 64-bit arithmetic, traps, "
						<code> "set -e"
						" and the special and regular built-ins, compared with dash 0.5.12 in 444 cases."
			<h2 className="section"> "Keys"
			<dl className="keys">
				<dt> "Ctrl-A, Ctrl-E, Home, End"
				<dd> "start and end of the line"
				<dt> "Ctrl-B, Ctrl-F, ←, →"
				<dd> "back and forward a character"
				<dt> "Alt-B, Alt-F, Ctrl-←, Ctrl-→"
				<dd> "back and forward a word"
				<dt> "Ctrl-K, Ctrl-U, Ctrl-W, Alt-D, Alt-Backspace"
				<dd> "kill to the end, to the start, the previous blank-separated word, the next word, the previous word"
				<dt> "Ctrl-Y"
				<dd> "yank the last kill"
				<dt> "Ctrl-T"
				<dd> "transpose characters"
				<dt> "Ctrl-P, Ctrl-N, ↑, ↓"
				<dd> "previous and next history entry"
				<dt> "Ctrl-R"
				<dd> "incremental reverse search; Ctrl-R again for older matches, Enter runs, Ctrl-G cancels"
				<dt> "Tab"
				<dd> "complete; a second Tab lists the candidates"
				<dt> "Ctrl-L"
				<dd> "clear the screen"
				<dt> "Ctrl-C, Ctrl-D"
				<dd> "discard the line; exit on an empty line"
				<dt> "Ctrl-Z"
				<dd>
					"stop the foreground job; "
					<code> "fg"
					" and "
					<code> "bg"
					" continue it"
			<h2 className="section"> "Resource limits"
			<p className="lead">
				"Run "
				<code> "ulimit -Sn"
				" to show the soft open-file limit, "
				<code> "ulimit -Hn"
				" to show the hard limit, or "
				<code> "ulimit -a"
				" to see all limits. Changes apply to the current shell and its children."
			<h2 className="section"> "Install"
			<pre>
				<code> "git clone https://github.com/Spaceghost/nelibc\nmake -C nelibc lib-standalone-zig\ngit clone https://github.com/Spaceghost/nebox\nmake -C nebox NELIBC=../nelibc           # build/nebox, one static binary\nln -s \"$PWD/nebox/build/nebox\" ~/.local/bin/nsh\nnsh"
			<p className="note">
				"Configuration goes in "
				<code> "~/.config/nsh/rc"
				" (run at startup as "
				<code> "ENV"
				"; plain shell). "
				<code> "sh -i"
				" is the same shell with POSIX defaults: "
				<code> "PS1='$ '"
				" and "
				<code> "~/.sh_history"
				"."
			<h2 className="section"> "Not there yet"
			<ul>
				<li>
					<code> "fc"
					", vi editing mode and "
					<code> "set -o emacs/vi"
					"."
				<li> "Characters are one column wide each: East Asian wide and combining characters misalign the cursor."
			<div className="actions">
				<a className="button" html:href="https://github.com/Spaceghost/nebox/tree/main/src/nebox/sh"> "Shell source"
				" "
				<a className="button button-ghost" html:href="https://github.com/Spaceghost/nebox/blob/main/tests/sh_interactive.py"> "Terminal tests"

export def footerLinks
	<div className="footer-links">
		<a html:href="https://github.com/Spaceghost/nebox"> "Spaceghost/nebox"
