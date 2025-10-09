require 'open-uri'
require 'nokogiri'
require 'json'

url = "https://ontarioreign.com/standings"
html = URI.open(url, "User-Agent" => "Mozilla/5.0").read
doc = Nokogiri::HTML(html)

lines = doc.text.gsub("\u00a0", " ").split("\n").map(&:strip).reject(&:empty?)
File.write("debug.txt", lines.join("\n"))

divisions = []
current_division = nil
teams = []

lines.each do |line|
  if line =~ /^(Pacific|Atlantic|North|Central) Division$/
    divisions << { division: current_division, teams: teams } if current_division
    current_division = line
    teams = []
  elsif line =~ /^\D+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+-\d+-\d+-\d+\s+\d+$/
    parts = line.split(/\s+/)
    name = parts[0..(parts.size - 16)].join(" ")
    stats = parts.last(16)
    teams << {
      team: name,
      gp: stats[0].to_i,
      gr: stats[1].to_i,
      w: stats[2].to_i,
      l: stats[3].to_i,
      otl: stats[4].to_i,
      sol: stats[5].to_i,
      pts: stats[6].to_i,
      pct: stats[7].to_f,
      rw: stats[8].to_i,
      row: stats[9].to_i,
      gf: stats[10].to_i,
      ga: stats[11].to_i,
      stk: stats[12],
      p10: stats[13].to_i,
      pim: stats[14].to_i
    }
  end
end

divisions << { division: current_division, teams: teams } if current_division

File.write("standings.json", JSON.pretty_generate(divisions))
puts "✅ Parsed #{divisions.sum { |d| d[:teams].size }} teams across #{divisions.size} divisions"
