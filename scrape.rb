require "bundler/setup"
require "capybara"
require "capybara/dsl"
require "nokogiri"
require "json"

Capybara.default_driver = :selenium_chrome_headless
Capybara.default_max_wait_time = 15

class Scraper
  include Capybara::DSL

  def run
    visit("https://theahl.com/stats/standings")
    unless page.has_css?("table.standings-table")
      puts "❌ Table not found"
      File.write("debug.html", page.html)
      return
    end

    html = page.html
    File.write("debug.html", html)
    puts "📄 Saved debug.html for inspection"

    doc = Nokogiri::HTML(html)
    rows = doc.css("table.standings-table tbody tr")
    puts "📊 Found #{rows.size} rows"

    teams = rows.map do |row|
      cols = row.css("td").map(&:text).map(&:strip)
      next unless cols.size >= 6
      {
        team: cols[0],
        gp: cols[1].to_i,
        w: cols[2].to_i,
        l: cols[3].to_i,
        ot: cols[4].to_i,
        pts: cols[5].to_i
      }
    end.compact

    File.write("standings.json", JSON.pretty_generate(teams))
    puts "✅ Parsed #{teams.size} teams"
  end
end

Scraper.new.run
