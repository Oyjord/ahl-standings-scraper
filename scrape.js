const { chromium } = require('playwright');
const fs = require('fs');

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  await page.goto('https://theahl.com/stats/standings', { waitUntil: 'domcontentloaded' });

  // ✅ Click Pacific tab and wait for table to update
  await page.click('text=Pacific');
  await page.waitForTimeout(2000);

  // ✅ Save raw HTML
  const html = await page.content();
  fs.writeFileSync('raw.html', html);
  console.log(`✅ Saved raw.html with ${html.length} characters`);

  const debug = [];

  // ✅ Wait for table
  try {
    await page.waitForSelector('table tbody tr', { timeout: 15000 });
    debug.push("✅ Table element found");
  } catch (err) {
    debug.push(`❌ Table not found: ${err.message}`);
    fs.writeFileSync('debug.txt', debug.join('\n'));
    console.log("❌ Table not found");
    await browser.close();
    return;
  }

  // ✅ Extract rows
  const rows = await page.$$eval('table tbody tr', trs =>
    trs.map(tr => Array.from(tr.querySelectorAll('td')).map(td => td.textContent.trim()))
  );

  debug.push(`✅ Found ${rows.length} table rows`);
  rows.slice(0, 10).forEach((row, i) => {
    debug.push(`Row ${i}: ${JSON.stringify(row)}`);
  });

  // ✅ Parse Pacific Division rows
  const pacific = rows
    .map(row => ({
      team: row[4],
      gp: parseInt(row[5]),
      gr: parseInt(row[6]),
      w: parseInt(row[7]),
      l: parseInt(row[8]),
      otl: parseInt(row[9]),
      sol: parseInt(row[10]),
      pts: parseInt(row[18])
    }))
    .filter(team => team.team);

  debug.push(`✅ Pacific teams found: ${pacific.length}`);
  fs.writeFileSync('debug.txt', debug.join('\n'));
  fs.writeFileSync('standings.json', JSON.stringify({ division: 'Pacific Division', teams: pacific }, null, 2));
  console.log(`✅ Parsed ${pacific.length} Pacific Division teams`);

  await browser.close();
})();
