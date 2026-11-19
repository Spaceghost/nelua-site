export const title = "Nelua Builders — a community source index"
export const description = "Meet the Nelua community. Explore a transparent index of current original public Nelua source and the people building it."

export def body
	<div className="community">
		<div className="page-details">
			<section className="hero" aria-labelledby="hero-title">
				<p className="eyebrow"> 'Community source index'
				<h1 id="hero-title"> 'Nelua builders'
				<p className="tagline"> 'Explore the people and projects growing Nelua.'
				<p className="blurb"> 'The index tracks original public source and includes authored totals from private projects that builders choose to count.'
				<div className="actions">
					<a className="button" href="#leaderboard"> 'Browse the index'
					<a className="text-link" href="api/auth/start" id="nav-sign-in"> 'Sign in with GitHub'
					<a className="text-link" href="#methodology"> 'How we count'
			<section className="stats" html:aria-label="Index totals">
				<div className="stat">
					<span className="stat-label"> "Builders"
					<strong html:id="stat-people"> "—"
				<div className="stat stat-highlight">
					<span className="stat-label"> "Original Nelua lines"
					<strong html:id="stat-lines"> "—"
				<div className="stat">
					<span className="stat-label"> "Public projects"
					<strong html:id="stat-repos"> "—"
			<section className="index-section" html:id="leaderboard" html:aria-labelledby="index-title">
				<div className="section-heading">
					<div>
						<h2 html:id="index-title"> "Builders and projects"
					<div className="snapshot">
						<span html:id="snapshot-label"> "Loading source snapshot…"
				<div className="toolbar">
					<div className="filters" html:role="group" html:aria-label="Builder type">
						<button className="filter active" html:data-type="all" html:aria-pressed="true"> "Everyone"
						<button className="filter" html:data-type="people" html:aria-pressed="false"> "People"
						<button className="filter" html:data-type="teams" html:aria-pressed="false"> "Teams"
					<label className="search">
						<span html:aria-hidden="true"> "⌕"
						<span className="sr-only"> "Search builders or projects"
						<input html:id="search" html:type="search" html:placeholder="Find a builder or project" html:autocomplete="off">
						<kbd html:aria-hidden="true"> "/"
					<label className="sort">
						<span className="sr-only"> "Sort the index"
						<select html:id="sort">
							<option html:value="lines"> "Most Nelua lines"
							<option html:value="repositories"> "Most projects"
							<option html:value="files"> "Most source files"
				<div className="table-wrap">
					<table>
						<thead>
							<tr>
								<th className="rank-head" html:scope="col"> "#"
								<th html:scope="col"> "Builder"
								<th className="number" html:scope="col">
									"Lines"
								<th className="number secondary-col" html:scope="col"> "FILES"
								<th className="number projects-head" html:scope="col"> "PROJECTS"
						<tbody html:id="builders">
							<tr>
								<td html:colspan="5" className="empty"> "Reading the public source snapshot…"
				<div className="table-footer">
					<span html:id="result-count" html:role="status" html:aria-live="polite"> "Loading the index"
					<button html:id="show-more" className="more-button" html:hidden="">
						"Show more builders"
					<a html:href="data.json" html:download="nelua-builders.json">
						"Download the data"
				<p className="ranking-note">
					"Ranked by current original "
					<code> ".nelua"
					" source on indexed public default branches, plus private lines attributed to participating owners' commits. Open a builder to explore its public projects."
			<p className="ranking-note" html:id="private-count-note" html:aria-live="polite"> "Private totals require explicit owner consent."
			<section className="private-panel" html:id="private-projects" html:aria-labelledby="private-title">
				<div>
					<h2 html:id="private-title"> "Include private projects"
					<p> "Sign in with GitHub, connect selected repositories, and choose which to count. Only current Nelua code attributed to your commits counts. Your combined totals appear publicly; repository names, file paths and code stay private."
				<aside className="refresh-notice" html:aria-label="Daily refresh schedule">
					<strong> "Updates daily at 7:17 a.m. Pacific"
					<p> "New projects and saved repository changes are included in the next daily refresh."
				<div html:id="account-controls">
					<a className="account-button" html:href="api/auth/start"> "Sign in with GitHub"
				<p html:id="account-status" className="account-status" html:role="status" html:aria-live="polite">
			<section html:id="methodology" className="methodology" html:aria-labelledby="method-title">
				<div className="method-intro">
					<h2 html:id="method-title"> "How we count"
					<p> "A useful community list starts with visible rules and links back to the source. Refreshed daily at 7:17 a.m. Pacific."
					<a html:href="data.json" html:download=""> "Inspect the full snapshot"
				<div className="method-rules">
					<article>
						<div>
							<h3> "A current footprint"
							<p> "Original public Nelua source on each indexed repository's default branch, across all time. Blank and comment-only lines are excluded."
					<article>
						<div>
							<h3> "One copy counts"
							<p> "Forks, known vendored and generated files, and exact duplicate source are excluded. The snapshot records coverage and unavailable repositories."
					<article>
						<div>
							<h3> "Projects belong to a community"
							<p> "Public projects aggregate under their GitHub repository owner, with project links and pinned commits. Private totals count only current code attributed to commits authored by the participating owner; other authors and unlinked identities are excluded."
					<div className="coverage-note" html:id="coverage-note"> "Coverage details are included in the downloadable snapshot."

export def footerLinks
	<div className="footer-links">
		<a href="https://github.com/topics/nelua"> 'Nelua projects on GitHub'
		<a href="https://nelua.io/"> 'Nelua documentation'
