// playoffs.js
const { chromium } = require('playwright');
const fs = require('fs');

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();

  const url = 'https://theahl.com/stats/playoffs/92';
  await page.goto(url, { waitUntil: 'domcontentloaded' });

  // Save raw HTML for inspection
  const html = await page.content();
  fs.writeFileSync('raw_playoffs.html', html);
  console.log(`✅ Saved raw_playoffs.html with ${html.length} characters`);

  const debug = [];
  debug.push(`URL: ${url}`);

  // This will likely need one tweak once you inspect raw_playoffs.html
  // but it's a safe starting point.
  try {
    await page.waitForSelector('.bracket, .bracket-wrapper, .playoff-bracket', { timeout: 15000 });
    debug.push('✅ Bracket container found');
  } catch (err) {
    debug.push(`❌ Bracket container not found: ${err.message}`);
    fs.writeFileSync('playoffs_debug.txt', debug.join('\n'));
    console.log('❌ Bracket container not found');
    await browser.close();
    return;
  }

  // Extract series data
  const series = await page.$$eval(
    // Try a few likely series selectors; you can tighten this after inspecting raw_playoffs.html
    '.bracket-series, .series, .matchup',
    (nodes) => {
      const results = [];

      nodes.forEach((node) => {
        // Find division by walking up to a heading
        let division = '';
        let round = '';

        let parent = node.parentElement;
        while (parent) {
          const divHeading =
            parent.querySelector('h2, h3, .division-title, .bracket-division-title');
          if (divHeading && !division) {
            division = divHeading.textContent.trim();
          }

          const roundHeading =
            parent.querySelector('.round-title, .bracket-round-title, h4');
          if (roundHeading && !round) {
            round = roundHeading.textContent.trim();
          }

          parent = parent.parentElement;
        }

        // Team names
        const awayEl =
          node.querySelector('.away .team-name, .team-away, .team--away, .team-name-away') ||
          node.querySelector('.team-name:nth-of-type(1)');
        const homeEl =
          node.querySelector('.home .team-name, .team-home, .team--home, .team-name-home') ||
          node.querySelector('.team-name:nth-of-type(2)');

        const away_team = awayEl ? awayEl.textContent.trim() : '';
        const home_team = homeEl ? homeEl.textContent.trim() : '';

        // Series tally like "1:2", "0:3", etc.
        const scoreEl =
          node.querySelector('.series-score, .score, .series-record') ||
          node.querySelector('.record');

        const series_score = scoreEl ? scoreEl.textContent.trim() : '';

        if (away_team || home_team || series_score) {
          results.push({
            division,
            round,
            away_team,
            home_team,
            series_score,
          });
        }
      });

      return results;
    }
  );

  debug.push(`✅ Parsed ${series.length} playoff series`);
  series.slice(0, 10).forEach((s, i) => {
    debug.push(`Series ${i}: ${JSON.stringify(s)}`);
  });

  fs.writeFileSync('playoffs_debug.txt', debug.join('\n'));
  fs.writeFileSync('playoffs.json', JSON.stringify(series, null, 2));
  console.log(`✅ Wrote playoffs.json with ${series.length} series`);

  await browser.close();
})();
