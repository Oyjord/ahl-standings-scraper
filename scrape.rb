require 'open-uri'
require 'nokogiri'
require 'json'

url = "https://ontarioreign.com/standings"
html = URI.open(url, "User-Agent" => "Mozilla/5.0").read
doc = Nokogiri::HTML(html)
text = doc.text.gsub("\u00a0", " ")  # replace non-breaking spaces

# Save full text for inspection
File.write("debug.txt", text)

# Match each division block
blocks = text.scan(/(Pacific|Atlantic|North|Central) Division\s+GP GR W L OTL SOL PTS PCT RW ROW GF GA STK P10 PIM\s+(.*?)(?=(?:Pacific|Atlantic|North|Central) Division|$)/m)

standings = blocks.map do |division, block|
  teams = block.scan(/^([A-Za-z\/\s\-]+?)\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+-\d+-\d+-\d+\s+\d+/)
  {
    division: division,
    teams: teams.map { |name| { team: name.strip } }
  }
end

File.write("standings.json", JSON.pretty_generate(standings))
puts "✅ Parsed #{standings.sum { |d| d[:teams].size }} teams across #{standings.size} divisions"
