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
    visit("https://www.flashscore.com/hockey/usa/ahl/standings/#/hUM5YvA6/standings/overall/")
    page.has_css?("div.table__row")  # wait for standings to load

    html = page.html
    File.write("debug.html", html)

    doc = Nokogiri::HTML(html)
    rows = doc.css("div.table__row")
    puts "📊 Found #{rows.size} rows"

    teams = rows.map do |row|
      cols = row.css("div.table__cell").map(&:text).map(&:strip)
      next unless cols.size >= 8
      {
        team: cols[1],
        gp: cols[2].to_i,
        w: cols[3].to_i,
        l: cols[4].to_i,
        ot: cols[5].to_i,
        pts: cols[7].to_i
      }
    end.compact

    File.write("standings.json", JSON.pretty_generate(teams))
    puts "✅ Parsed #{teams.size} teams"
  end
end

Scraper.new.run
