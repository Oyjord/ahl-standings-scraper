const { chromium } = require('playwright');
const fs = require('fs');

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  await page.goto('https://theahl.com/stats/standings', { waitUntil: 'domcontentloaded' });

  // ✅ Save raw HTML for inspection
  const html = await page.content();
  fs.writeFileSync('raw.html', html);
  console.log(`✅ Saved raw.html with ${html.length} characters`);

  const debug = [];

  // ✅ Try to wait for any table to appear
  try {
    await page.waitForSelector('table', { timeout: 15000 });
    debug.push("✅ Table element found");
  } catch (err) {
    debug.push(`❌ Table not found: ${err.message}`);
    fs.writeFileSync('debug.txt', debug.join('\n'));
    console.log("❌ Table not found");
    await browser.close();
    return;
  }

  // ✅ Extract all rows from any table
  const rows = await page.$$eval('table tbody tr', trs =>
    trs.map(tr => Array.from(tr.querySelectorAll('td')).map(td => td.textContent.trim()))
  );

  debug.push(`✅ Found ${rows.length} table rows`);

  // ✅ Log first 10 rows for inspection
  rows.slice(0, 10).forEach((row, i) => {
    debug.push(`Row ${i}: ${JSON.stringify(row)}`);
  });

  // ✅ Filter Pacific Division rows
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
