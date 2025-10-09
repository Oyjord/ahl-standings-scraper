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
    # Save previous division
    divisions << { division: current_division, teams: teams } if current_division
    current_division = line
    teams = []
  elsif line =~ /^\D+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+-\d+-\d+-\d+\s+\d+$/
    team_name = line[/^(.+?)\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+-\d+-\d+-\d+\s+\d+$/, 1]
    teams << { team: team_name.strip }
  end
end

# Add final division
divisions << { division: current_division, teams: teams } if current_division

File.write("standings.json", JSON.pretty_generate(divisions))
puts "✅ Parsed #{divisions.sum { |d| d[:teams].size }} teams across #{divisions.size} divisions"
