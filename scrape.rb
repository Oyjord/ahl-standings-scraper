require 'ferrum'
require 'nokogiri'
require 'json'

browser = Ferrum::Browser.new
browser.goto("https://theahl.com/stats/standings")

# Wait up to 15 seconds for the table to appear
max_wait = 15
start_time = Time.now

until browser.at_css("table.standings-table") || Time.now - start_time > max_wait
  sleep 1
end

unless browser.at_css("table.standings-table")
  puts "❌ Table not found after #{max_wait} seconds"
  File.write("debug.html", browser.body)
  browser.quit
  exit
end

html = browser.body
File.write("debug.html", html)
puts "📄 Saved debug.html for inspection"

doc = Nokogiri::HTML(html)
rows = doc.css("table.standings-table tbody tr")
puts "📊 Found #{rows.size} rows in standings table"

teams = []

rows.each_with_index do |row, i|
  cols = row.css("td").map(&:text).map(&:strip)
  puts "🔍 Row #{i}: #{cols.inspect}"

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
