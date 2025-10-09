require 'open-uri'
require 'nokogiri'
require 'json'

url = "https://ontarioreign.com/standings"
html = URI.open(url, "User-Agent" => "Mozilla/5.0").read
doc = Nokogiri::HTML(html)

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

  tokens = line.split(/\s+/)
  next unless tokens.size >= 21  # team name + 20 stats

  stats = tokens.last(20)
  name = tokens[0..(tokens.size - 21)].join(" ")
  pacific << {
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
    diff: stats[12].to_i,
    home: stats[13],
    away: stats[14],
    stk: stats[15],
    p10: stats[16],
    pim: stats[17].to_i,
    rank: stats[18].to_i
  }
end

File.write("standings.json", JSON.pretty_generate({ division: "Pacific Division", teams: pacific }))
puts "✅ Parsed #{pacific.size} Pacific Division teams"
