import { parseCatalog } from '../applet-catalog.mjs'

export const title = 'Nebox applet coverage · Nelua'
export const description = 'Check which BusyBox and Toybox commands Nebox provides as executables or shell builtins.'

def cell value
	<td className=(value == 'Missing' ? 'missing' : value == '—' ? 'unused' : 'present')> value

export def body source
	const catalog = parseCatalog(source)
	<article className="coverage-page">
		<header className="coverage-heading">
			<a href="/nelua/nebox/"> '← Nebox'
			<h1> 'Applet coverage'
			<p> "Every command name in BusyBox {catalog.busyboxVersion} or Toybox {catalog.toyboxVersion}, including aliases and optional applets."
			<dl className="coverage-totals">
				for item in catalog.totals
					<div>
						<dt> item.label
						<dd> item.count
			<p className="coverage-evidence">
				'Verified 21 November 2026 · '
				<a href="https://github.com/Spaceghost/nebox/commit/b948bce"> 'Nebox b948bce'
				' · '
				<a href="/nelua/nebox/applet-coverage.txt"> 'Plain text'
		<section aria-labelledby="commands">
			<h2 id="commands"> 'Command directory'
			<p className="coverage-key"> 'Covered commands have every invocation form their upstreams declare. A dash means neither project requires that form. “Toybox shell” marks an upstream shell builtin.'
			<div className="coverage-controls" id="coverage-filters" html:hidden="">
				<div className="coverage-field">
					<label for="coverage-query"> 'Find a command'
					<input id="coverage-query" type="search" placeholder="e.g. gzip" autocomplete="off" spellcheck="false">
				<div className="coverage-field">
					<label for="coverage-status"> 'Nebox coverage'
					<select id="coverage-status">
						<option value=""> 'All commands'
						<option value="covered"> 'Covered'
						<option value="missing"> 'Missing'
				<div className="coverage-field">
					<label for="coverage-upstream"> 'Upstream'
					<select id="coverage-upstream">
						<option value=""> 'All projects'
						<option value="both"> 'Both projects'
						<option value="busybox"> 'BusyBox only'
						<option value="toybox"> 'Toybox only'
				<button type="button" id="coverage-clear"> 'Clear filters'
			<p id="coverage-results" html:role="status"> "{catalog.rows.length} commands"
			<div className="coverage-scroll" html:role="region" aria-label="Command coverage table" html:tabindex="0">
				<table aria-labelledby="commands">
					<thead>
						<tr>
							<th scope="col"> 'Command'
							<th scope="col"> 'Upstream'
							<th scope="col">
								<span className="coverage-owner"> 'Nebox '
								'executable'
							<th scope="col">
								<span className="coverage-owner"> 'Nebox '
								'shell'
					<tbody>
						for row in catalog.rows
							<tr data-upstream=row.upstream data-status=row.status>
								<th scope="row"> <code> row.name
								<td>
									if row.busybox
										<span> 'BusyBox'
									if row.toybox
										if row.busybox
											' · '
										<span> (row.toybox == 'shell' ? 'Toybox shell' : 'Toybox')
								cell(row.executable)
								cell(row.shell)
		<section className="coverage-extras" aria-labelledby="extras">
			<h2 id="extras"> 'Additional Nebox commands'
			<p> 'These names are available in Nebox and fall outside both upstream catalogs.'
			<ul className="applets">
				for name in catalog.extras
					<li> name
