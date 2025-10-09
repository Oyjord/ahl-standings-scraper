require 'open-uri'
require 'nokogiri'
require 'json'

url = "https://icehogs.com/standings"
html = URI.open(url, "User-Agent" => "Mozilla/5.0").read
doc = Nokogiri::HTML(html)

lines = doc.text.gsub("\u00a0", " ").split("\n").map(&:strip).reject(&:empty?)
timestamp = Time.now.strftime("%Y-%m-%d %H:%M:%S")
File.write("raw.html", html)

debug_log = ["Scraped at #{timestamp}", "📊 Total lines scraped: #{lines.size}", ""]
pacific = []
in_pacific = false
parsed = 0
skipped = 0

lines.each_with_index do |line, i|
  if line == "Pacific Division"
    in_pacific = true
    debug_log << "🔍 Entered Pacific Division block at line #{i}"
    next
  elsif line =~ /Division$/ && line != "Pacific Division"
    in_pacific = false
    debug_log << "🚪 Exited Pacific Division block at line #{i}"
  end

  next unless in_pacific
  next if line.include?("GP") && line.include?("PTS") # skip header

  debug_log << "📄 Line #{i}: #{line.inspect}"

  tokens = line.split(/\s+/)
  debug_log << "→ Token count: #{tokens.size}"

  if tokens.size >= 8
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
    parsed += 1
    debug_log << "✅ Parsed: #{name.strip}"
  else
    skipped += 1
    debug_log << "⚠️ Skipped: not enough tokens"
  end
  debug_log << ""
end

debug_log << "✅ Final count: #{parsed} parsed, #{skipped} skipped"
File.write("debug.txt", debug_log.join("\n"))
File.write("standings.json", JSON.pretty_generate({ division: "Pacific Division", teams: pacific }))
puts "✅ Parsed #{parsed} Pacific Division teams"
