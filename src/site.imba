import { createHash } from 'node:crypto'
import { copyFileSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs'
import * as overview from './pages/overview.imba'
import * as compiler from './pages/compiler.imba'
import * as comptime from './pages/comptime.imba'
import * as syntaxGuide from './pages/syntax-guide.imba'
import * as nelibc from './pages/nelibc.imba'
import * as nebox from './pages/nebox.imba'
import * as nsh from './pages/nsh.imba'
import * as init from './pages/init.imba'
import * as community from './pages/community.imba'
import * as notFound from './pages/not-found.imba'

const navigation = [
	{ label: 'Overview', path: '/nelua/' }
	{ label: 'Compiler', path: '/nelua/compiler/' }
	{ label: 'nelibc', path: '/nelua/nelibc/' }
	{ label: 'nebox', path: '/nelua/nebox/' }
	{ label: 'Init', path: '/nelua/init/' }
	{ label: 'Community', path: '/nelua/community/' }
]

def content filename
	readFileSync("src/content/{filename}.html", 'utf8').trim()

def asset path
	const hash = createHash('sha256').update(readFileSync('public' + path)).digest('hex').slice(0, 12)
	"{path}?v={hash}"

def documentFor page
	const active = page.active || page.path
	const current = page.path == active ? 'page' : 'location'
	const view = page.source
	<html lang="en">
		<head>
			<meta charset="utf-8">
			<meta name="viewport" content="width=device-width, initial-scale=1">
			<meta name="theme-color" content="#ffffff">
			<title> view.title
			if view.description
				<meta name="description" content=view.description>
			if page.path != '/nelua/404.html'
				<link rel="canonical" href=('https://spacegho.st' + page.path)>
			<link rel="stylesheet" href=asset('/nelua/assets/site.css')>
			<link rel="icon" href="/nelua/assets/icon.svg" type="image/svg+xml">
			if page.path == '/nelua/community/'
				<link rel="stylesheet" href=asset('/nelua/community/styles.css')>
			for script in page.scripts || []
				<script src=asset(script) html:defer="">
		<body>
			<a className="skip-link" href="#main"> 'Skip to content'
			<div className="wrap">
				<header className="top">
					<a className="home" href="/nelua/">
						<span className="monogram" aria-hidden="true"> 'n'
						<span> 'Nelua'
					<nav aria-label="Sections">
						for item in navigation
							<a href=item.path aria-current=(item.path == active ? current : null)> item.label
						<a href="https://nelua.io/" rel="external"> 'nelua.io'
				<main id="main" html:tabindex="-1">
					page.body
				<footer>
					<a className="footer-home" href="/nelua/"> 'Nelua at spacegho.st'
					if view.footerLinks
						view.footerLinks()
					else
						<div className="footer-links">
							<a href="https://github.com/Spaceghost/nelua-site"> 'Site source'
							<a href="https://johnneylee.com/"> 'Johnneylee Rollins'

const pages = [
	{ source: overview, path: '/nelua/', body: overview.body(content('nelibc-overview')) }
	{ source: compiler, path: '/nelua/compiler/', body: compiler.body() }
	{ source: comptime, path: '/nelua/compiler/comptime/', active: '/nelua/compiler/', body: comptime.body() }
	{ source: syntaxGuide, path: '/nelua/compiler/syntax-extensions/', active: '/nelua/compiler/', body: syntaxGuide.body(content('syntax-guide'), content('syntax-toc')) }
	{ source: nelibc, path: '/nelua/nelibc/', body: nelibc.body(content('nelibc-comparison'), content('nelibc-stats')), scripts: ['/nelua/assets/explorer.js'] }
	{ source: nebox, path: '/nelua/nebox/', body: nebox.body() }
	{ source: nsh, path: '/nelua/nebox/nsh/', active: '/nelua/nebox/', body: nsh.body() }
	{ source: init, path: '/nelua/init/', body: init.body() }
	{ source: community, path: '/nelua/community/', body: community.body(), scripts: ['/nelua/community/app.js', '/nelua/community/account.js'] }
	{ source: notFound, path: '/nelua/404.html', body: notFound.body() }
]

copyFileSync('src/site.css', 'public/nelua/assets/site.css')
copyFileSync('src/community.css', 'public/nelua/community/styles.css')

for page in pages
	const output = 'public' + page.path + (page.path.endsWith('/') ? 'index.html' : '')
	if page.path.endsWith('/')
		mkdirSync('public' + page.path, { recursive: true })
	const html = documentFor(page).outerHTML.replace(/^<!DOCTYPE html>/, '<!doctype html>\n')
	writeFileSync(output, html + '\n')

console.log("Rendered {pages.length} Nelua pages")
