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
  rows.slice(0, 10).forEach((row, i) => {
    debug.push(`Row ${i}: ${JSON.stringify(row)}`);
  });

  // ✅ Division ID to name mapping
  const divisionMap = {
    "1": "Atlantic",
    "2": "North",
    "3": "Central",
    "4": "Pacific"
  };

  // ✅ Parse all teams with correct indexes
  const teams = rows
    .map(row => {
      if (row.length < 19) return null;
      return {
        team: row[3],                          // Full team name
        division: divisionMap[row[1]] || "?", // Division name from ID
        gp: parseInt(row[4]),
        gr: parseInt(row[5]),
        w: parseInt(row[6]),
        l: parseInt(row[7]),
        otl: parseInt(row[8]),
        sol: parseInt(row[9]),
        pts: parseInt(row[18])
      };
    })
    .filter(team => team && team.team);

  debug.push(`✅ Parsed ${teams.length} teams across all divisions`);
  fs.writeFileSync('debug.txt', debug.join('\n'));
  fs.writeFileSync('standings.json', JSON.stringify({ division: 'All Divisions', teams }, null, 2));
  console.log(`✅ Parsed ${teams.length} teams`);

  await browser.close();
})();
