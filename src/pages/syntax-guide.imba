export const title = "Syntax extensions: the full guide · Nelua · spacegho.st"
export const description = "Load Nelua syntax modules for control flow, lambdas, destructuring, scoped resources, comprehensions, literals, pipes and interpolation. A complete guide to file-local grammars, templates, precedence and reusable packs."

export def body guide, toc
	<div className="page-content">
		<section className="hero">
			<p className="eyebrow"> "Compiler · syntax workshop"
			<h1> "Make room for your notation"
			<p className="tagline"> "A full guide to Nelua's file-local syntax extensions."
			<p className="blurb"> "Start with the opt-in library, compose a project pack, then build your own grammar rules. Every form becomes ordinary Nelua before type checking."
			<div className="actions">
				<a className="button" html:href="#start-here"> "Try the complete pack"
				" "
				<a className="button button-ghost" html:href="#write-an-inline-extension"> "Write an extension"
			<p>
				<a href="/nelua/examples/life/"> 'Try a project-local Bend syntax extension in the browser'
		<div className="guide-layout">
			<nav className="guide-toc" html:aria-label="Guide contents">
				<p className="eyebrow"> "In this guide"
				<ol innerHTML=toc>
			<article className="guide-article" html:id="guide" html:tabindex="-1" innerHTML=guide>

export def footerLinks
	<div className="footer-links">
		<a html:href="/nelua/compiler/"> "Compiler"
		<a html:href="https://github.com/Spaceghost/nelua/blob/master/docs/pages/syntax-extensions.md"> "Guide source "
		<a html:href="https://github.com/Spaceghost/nelua/blob/master/examples/syntax_tour.nelua"> "Runnable tour "
