# frozen_string_literal: true

require 'mechanize'
require 'scraperwiki'

HEADERS = {
  'HTTP_USER_AGENT': 'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9.0.13) Gecko/2009073022 Firefox/3.0.13',
  'HTTP_ACCEPT': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3',
  'Content-Type': 'text/html; charset=UTF-8'
}.freeze

PER_PAGE = 100
BASE_URL = 'http://our-stores.iga.com.au/jm-ajax/get_listings'

agent = Mechanize.new

# 1. Retrieve number of pages to be scraped
raw_response = agent.get("#{BASE_URL}?page=0&per_page=#{PER_PAGE}")
parsed_json = JSON.parse(raw_response.body)
pages_count = parsed_json.fetch('max_num_pages')

# 2. Scrape and profit
(0..pages_count).each do |page_number|
  raw_page = agent.get("#{BASE_URL}?page=#{page_number}&per_page=#{PER_PAGE}")
  json = JSON.parse(raw_page.body)
  raw_html = Nokogiri::HTML(json.fetch('html'))
  available_stores = raw_html.search('.job_listing')

  available_stores.each do |store_row|
    attributes = store_row.attributes

    record = {
      external_id: attributes.fetch('data-id').value,
      name: attributes.fetch('data-title').value,
      link: attributes.fetch('data-link').value,
      address: attributes.fetch('data-address').value,
      latitude: attributes.fetch('data-latitude', nil)&.value, # this is optional but nice to have
      longitude: attributes.fetch('data-longitude', nil)&.value # this is optional but nice to have
    }

    ScraperWiki.save_sqlite([:external_id], record)
  end
end
