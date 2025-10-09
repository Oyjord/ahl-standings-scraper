require 'ferrum'
require 'nokogiri'
require 'json'

browser = Ferrum::Browser.new
browser.goto("https://theahl.com/stats/standings")
browser.network.wait_for_idle
sleep 5  # crude wait for JS to render

html = browser.body
doc = Nokogiri::HTML(html)

teams = []
doc.css("table.standings-table tbody tr").each do |row|
  cols = row.css("td").map(&:text)
  next unless cols.size >= 6

  teams << {
    team: cols[0],
    gp: cols[1].to_i,
    w: cols[2].to_i,
    l: cols[3].to_i,
    ot: cols[4].to_i,
    pts: cols[5].to_i
  }
end

File.write("standings.json", JSON.pretty_generate(teams))
browser.quit
