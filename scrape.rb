require 'open-uri'
require 'nokogiri'
require 'json'

url = "https://ontarioreign.com/standings"
html = URI.open(url, "User-Agent" => "Mozilla/5.0").read
doc = Nokogiri::HTML(html)

# Normalize tabs and non-breaking spaces
lines = doc.text.gsub("\u00a0", " ").split("\n").map(&:strip).reject(&:empty?)
timestamp = Time.now.strftime("%Y-%m-%d %H:%M:%S")
File.write("debug.txt", "Scraped at #{timestamp}\n\n" + lines.join("\n"))

pacific = []
in_pacific = false

lines.each do |line|
  if line == "Pacific Division"
    in_pacific = true
    next
  elsif line =~ /Division$/ && line != "Pacific Division"
    in_pacific = false
  end

  next unless in_pacific
  next if line.include?("GP") && line.include?("PTS") # skip header

  tokens = line.split("\t")
  next unless tokens.size >= 8  # team name + 7 stats

  name = tokens[0..(tokens.size - 8)].join(" ")
  stats = tokens.last(7)

  pacific << {
    team: name.strip,
    gp: stats[0].to_i,
    gr: stats[1].to_i,
    w: stats[2].to_i,
    l: stats[3].to_i,
    otl: stats[4].to_i,
    sol: stats[5].to_i,
    pts: stats[6].to_i
  }
end

File.write("standings.json", JSON.pretty_generate({ division: "Pacific Division", teams: pacific }))
puts "✅ Parsed #{pacific.size} Pacific Division teams"
