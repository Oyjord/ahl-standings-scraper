require 'nokogiri'
require 'open-uri'
require 'json'

url = "https://www.flashscore.com/hockey/usa/ahl/standings/#/hUM5YvA6/standings/overall/"
html = URI.open(url, "User-Agent" => "Mozilla/5.0").read
File.write("debug.html", html)
puts "📄 Saved debug.html for inspection"

doc = Nokogiri::HTML(html)

# Flashscore uses dynamic class names, so we target by structure
rows = doc.css("div.table__row--group")
puts "📊 Found #{rows.size} rows"

teams = []

rows.each_with_index do |row, i|
  cols = row.css("div.table__cell").map(&:text).map(&:strip)
  puts "🔍 Row #{i}: #{cols.inspect}"

  next unless cols.size >= 8

  teams << {
    team: cols[1],
    gp: cols[2].to_i,
    w: cols[3].to_i,
    l: cols[4].to_i,
    ot: cols[5].to_i,
    pts: cols[7].to_i
  }
end

puts "✅ Parsed #{teams.size} teams"
File.write("standings.json", JSON.pretty_generate(teams))
