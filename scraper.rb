#!/usr/bin/env ruby
# frozen_string_literal: true

# This is a template for a Ruby scraper on morph.io (https://morph.io)

Bundler.require

require "httparty"
require "scraperwiki"

class Scraper
  BASE_URL = "https://pdonline.frasercoast.qld.gov.au"

  def self.run
    date_scraped = Date.today.iso8601
    count = 0
    [
      "#{BASE_URL}/app-results?q=submitted-this-month",
      "#{BASE_URL}/app-results?q=submitted-last-month",
    ].each do |url|
      HTTParty.get(url).each do |a|
        id = a['uniqueId']
        address = a["property"].to_s.gsub(/\s+Qld\s+/, " QLD ").strip
        council_reference = a["applicationId"]
        date_received = Date.parse(a["submitted"]) unless a["submitted"].to_s.empty?

        record = {
          "council_reference" => council_reference,
          "address" => address,
          "description" => a["description"].strip,
          "info_url" => "#{BASE_URL}/#/applications/details?id=#{id}&applicationId=#{council_reference}",
          "date_scraped" => date_scraped,
          "date_received" => date_received&.iso8601,
        }
        puts "Saving #{council_reference} - #{address}"
        ScraperWiki.save_sqlite(["council_reference"], record)
        puts "RECORD: #{record.inspect}" if ENV['DEBUG']
        count += 1
      end
    end
    puts "",
         "Found #{count} records."
  end
end

# Run the scraper whilst allowing this file to be required in tests without auto-execution
Scraper.run if __FILE__ == $PROGRAM_NAME
