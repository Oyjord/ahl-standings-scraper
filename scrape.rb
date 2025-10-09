require 'open-uri'
require 'nokogiri'
require 'json'

url = "https://theahl.com/stats/standings"
html = URI.open(url, "User-Agent" => "Mozilla/5.0").read
doc = Nokogiri::HTML(html)

timestamp = Time.now.strftime("%Y-%m-%d %H:%M:%S")
File.write("raw.html", html)

debug_log = ["Scraped at #{timestamp}"]
pacific = []
parsed = 0
skipped = 0

doc.css("table.standings-table tbody tr").each_with_index do |row, i|
  cells = row.css("td").map { |td| td.text.strip }

  debug_log << "Row #{i}: #{cells.inspect}"

  next unless cells[1] == "Pacific" # Division column

  begin
    pacific << {
      team: cells[0],
      gp: cells[2].to_i,
      gr: cells[3].to_i,
      w: cells[4].to_i,
      l: cells[5].to_i,
      otl: cells[6].to_i,
      sol: cells[7].to_i,
      pts: cells[8].to_i
    }
    parsed += 1
    debug_log << "✅ Parsed: #{cells[0]}"
  rescue => e
    skipped += 1
    debug_log << "⚠️ Skipped: #{e.message}"
  end
end

debug_log << "✅ Final count: #{parsed} parsed, #{skipped} skipped"
File.write("debug.txt", debug_log.join("\n"))
File.write("standings.json", JSON.pretty_generate({ division: "Pacific Division", teams: pacific }))
puts "✅ Parsed #{parsed} Pacific Division teams"
