const { chromium } = require('playwright');
const fs = require('fs');

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  await page.goto('https://theahl.com/stats/standings', { waitUntil: 'domcontentloaded' });

  // ✅ Wait for the table to appear
  try {
    await page.waitForSelector('table.standings-table tbody tr', { timeout: 10000 });
  } catch (err) {
    fs.writeFileSync('debug.txt', `❌ Table not found: ${err.message}`);
    console.log("❌ Table not found");
    await browser.close();
    return;
  }

  // ✅ Extract all rows
  const rows = await page.$$eval('table.standings-table tbody tr', trs =>
    trs.map(tr => Array.from(tr.querySelectorAll('td')).map(td => td.textContent.trim()))
  );

  // ✅ Log row count and first few rows
  let debug = [`✅ Total rows scraped: ${rows.length}`];
  rows.slice(0, 5).forEach((row, i) => {
    debug.push(`Row ${i}: ${JSON.stringify(row)}`);
  });

  // ✅ Filter Pacific Division
  const pacific = rows
    .filter(row => row[1] === 'Pacific')
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

  debug.push(`✅ Pacific teams found: ${pacific.length}`);
  fs.writeFileSync('debug.txt', debug.join('\n'));
  fs.writeFileSync('standings.json', JSON.stringify({ division: 'Pacific Division', teams: pacific }, null, 2));
  console.log(`✅ Parsed ${pacific.length} Pacific Division teams`);

  await browser.close();
})();
