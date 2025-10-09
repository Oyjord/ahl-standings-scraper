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

  // ✅ Extract all rows
  const rows = await page.$$eval('table tbody tr', trs =>
    trs.map(tr => Array.from(tr.querySelectorAll('td')).map(td => td.textContent.trim()))
  );

  debug.push(`✅ Found ${rows.length} table rows`);

  // ✅ Log first 10 rows for inspection
  rows.slice(0, 10).forEach((row, i) => {
    debug.push(`Row ${i}: ${JSON.stringify(row)}`);
  });

  // ✅ Parse all teams with division tagging
  const teams = rows
    .map(row => {
      if (row.length < 19) return null; // skip malformed rows
      return {
        team: row[4],
        division: row[1],
        gp: parseInt(row[5]),
        gr: parseInt(row[6]),
        w: parseInt(row[7]),
        l: parseInt(row[8]),
        otl: parseInt(row[9]),
        sol: parseInt(row[10]),
        pts: parseInt(row[18])
      };
    })
    .filter(team => team && team.team); // skip nulls and blanks

  debug.push(`✅ Parsed ${teams.length} teams across all divisions`);
  fs.writeFileSync('debug.txt', debug.join('\n'));
  fs.writeFileSync('standings.json', JSON.stringify({ division: 'All Divisions', teams }, null, 2));
  console.log(`✅ Parsed ${teams.length} teams`);

  await browser.close();
})();
