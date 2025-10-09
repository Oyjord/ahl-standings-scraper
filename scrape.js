const { chromium } = require('playwright');
const fs = require('fs');

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  await page.goto('https://theahl.com/stats/standings', { waitUntil: 'domcontentloaded' });

  // ✅ Wait for the table to appear
  await page.waitForSelector('table.standings-table tbody tr', { timeout: 10000 });

  const rows = await page.$$eval('table.standings-table tbody tr', trs =>
    trs.map(tr => Array.from(tr.querySelectorAll('td')).map(td => td.textContent.trim()))
  );

  const pacific = rows
    .filter(row => row[1] === 'Pacific') // Division column
    .map(row => ({
      team: row[0],
      gp: parseInt(row[2]),
      gr: parseInt(row[3]),
      w: parseInt(row[4]),
      l: parseInt(row[5]),
      otl: parseInt(row[6]),
      sol: parseInt(row[7]),
      pts: parseInt(row[8])
    }));

  fs.writeFileSync('standings.json', JSON.stringify({ division: 'Pacific Division', teams: pacific }, null, 2));
  fs.writeFileSync('debug.txt', `✅ Total rows scraped: ${rows.length}\n✅ Pacific teams: ${pacific.length}`);
  console.log(`✅ Parsed ${pacific.length} Pacific Division teams`);

  await browser.close();
})();
