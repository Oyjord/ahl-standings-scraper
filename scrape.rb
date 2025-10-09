require 'ferrum'
require 'nokogiri'
require 'json'

browser = Ferrum::Browser.new
browser.goto("https://theahl.com/stats/standings")
browser.network.wait_for_idle
sleep 5  # crude wait for JS to render

html = browser.body
File.write("debug.html", html)  # fallback for inspection
puts "📄 Saved debug.html for inspection"

doc = Nokogiri::HTML(html)
rows = doc.css("table.standings-table tbody tr")
puts "📊 Found #{rows.size} rows in standings table"

teams = []

rows.each_with_index do |row, i|
  cols = row.css("td").map(&:text).map(&:strip)
  puts "🔍 Row #{i}: #{cols.inspect}"

  # Loosen guard: only skip if critical columns are missing
  next unless cols[0] && cols[1] && cols[2] && cols[3] && cols[4] && cols[5]

  teams << {
    team: cols[0],
    gp: cols[1].to_i,
    w: cols[2].to_i,
    l: cols[3].to_i,
    ot: cols[4].to_i,
    pts: cols[5].to_i
  }
end

puts "✅ Parsed #{teams.size} teams"
File.write("standings.json", JSON.pretty_generate(teams))
browser.quit
