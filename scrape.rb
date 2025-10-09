require 'open-uri'
require 'nokogiri'
require 'json'

url = "https://griffinshockey.com/standings"
html = URI.open(url, "User-Agent" => "Mozilla/5.0").read
doc = Nokogiri::HTML(html)

lines = doc.text.gsub("\u00a0", " ").gsub("\t", " ").split("\n").map(&:strip).reject(&:empty?)
timestamp = Time.now.strftime("%Y-%m-%d %H:%M:%S")
File.write("raw.html", html)

debug_log = ["Scraped at #{timestamp}", "📊 Total lines scraped: #{lines.size}", ""]
raw_pacific = []
in_pacific = false

lines.each_with_index do |line, i|
  debug_log << "Line #{i}: #{line.inspect}"

  if line == "Pacific Division"
    in_pacific = true
    debug_log << "🔍 Entered Pacific Division block at line #{i}"
    next
  elsif line =~ /Division$/ && line != "Pacific Division"
    in_pacific = false
    debug_log << "🚪 Exited Pacific Division block at line #{i}"
  end

  debug_log << "→ In Pacific? #{in_pacific}"

  if in_pacific
    debug_log << "📄 [Pacific] Line #{i}: #{line.inspect}"
    raw_pacific << line
  end
end

debug_log << "✅ Final count: #{raw_pacific.size} raw lines captured"
File.write("debug.txt", debug_log.join("\n"))
File.write("standings.json", JSON.pretty_generate({ division: "Pacific Division", raw_lines: raw_pacific }))
puts "✅ Captured #{raw_pacific.size} raw Pacific Division lines"
