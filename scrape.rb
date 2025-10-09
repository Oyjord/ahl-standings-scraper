require 'nokogiri'
require 'open-uri'
require 'json'

url = "https://ontarioreign.com/standings"
html = URI.open(url, "User-Agent" => "Mozilla/5.0").read
doc = Nokogiri::HTML(html)

# Extract semantic content block
raw = doc.at('script[type="application/ld+json"]')&.text
File.write("debug.json", raw) if raw

# Fallback: parse visible text
text = doc.text
divisions = text.scan(/(Pacific|Atlantic|North|Central) Division\s+GP GR W L OTL SOL PTS PCT RW ROW GF GA STK P10 PIM\s+(.*?)\s+(?=(?:Pacific|Atlantic|North|Central) Division|$)/m)

standings = divisions.map do |division, block|
  teams = block.scan(/([A-Za-z\/\s\-]+)\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+/)
  {
    division: division,
    teams: teams.map { |name| { team: name.strip } }
  }
end

File.write("standings.json", JSON.pretty_generate(standings))
puts "✅ Parsed #{standings.sum { |d| d[:teams].size }} teams"
