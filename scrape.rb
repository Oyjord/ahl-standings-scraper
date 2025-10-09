require 'nokogiri'
require 'open-uri'
require 'json'

url = "https://ontarioreign.com/standings"
html = URI.open(url, "User-Agent" => "Mozilla/5.0").read
doc = Nokogiri::HTML(html)

standings = []

doc.css("div.standings-table").each do |division_block|
  division_name = division_block.at("h2")&.text&.strip
  next unless division_name

  rows = division_block.css("table tbody tr")
  teams = rows.map do |row|
    cells = row.css("td").map { |td| td.text.strip }
    next unless cells.size >= 8

    {
      team: cells[0],
      gp: cells[1].to_i,
      w: cells[2].to_i,
      l: cells[3].to_i,
      otl: cells[4].to_i,
      sol: cells[5].to_i,
      pts: cells[6].to_i,
      pct: cells[7].to_f
    }
  end.compact

  standings << { division: division_name, teams: teams }
end

File.write("standings.json", JSON.pretty_generate(standings))
puts "✅ Parsed #{standings.sum { |d| d[:teams].size }} teams across #{standings.size} divisions"
