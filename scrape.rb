require 'open-uri'
require 'json'

url = "https://ontarioreign.com/standings"
html = URI.open(url, "User-Agent" => "Mozilla/5.0").read

# Extract semantic block
raw = html[/Ontario Reign \| Standings Standings(.*?)The official website/m, 1]
File.write("debug.txt", raw) if raw

divisions = raw.scan(/(Pacific|Atlantic|North|Central) Division\s+GP GR W L OTL SOL PTS PCT RW ROW GF GA STK P10 PIM\s+(.*?)(?=(?:Pacific|Atlantic|North|Central) Division|$)/m)

standings = divisions.map do |division, block|
  teams = block.scan(/([A-Za-z\/\s\-]+?)\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+-\d+-\d+-\d+\s+\d+/)
  {
    division: division,
    teams: teams.map { |name| { team: name.strip } }
  }
end

File.write("standings.json", JSON.pretty_generate(standings))
puts "✅ Parsed #{standings.sum { |d| d[:teams].size }} teams across #{standings.size} divisions"
