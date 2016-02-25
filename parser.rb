# -*- coding: utf-8 -*-
# frozen_string_literal: true
require 'open-uri'
require 'net/http'
require 'csv'

require 'nokogiri'

BASE_URL = 'http://www.clir.org/pubs/reports'.freeze

@doc = File.open('snippet.html') { |f| Nokogiri::HTML(f) }

def test_url(url)
  uri = URI.parse(url)
  request = Net::HTTP.new(uri.host, uri.port)
  response = request.request_head(uri.path)
  "#{url} is missing" if response.code != '200'
end

def find_redirect(uri)
  res = Net::HTTP.get_response(URI(uri.to_s))
  res['location'] = uri if res['location'].nil?
  res['location']
end

def find_isbn(string)
  (/ISBN\x20\d{1,5}([- ])\d{1,7}\1\d{1,6}\1(\d{1,6}|X)(\1\d)?/).match(string.to_s)
end

def main

  file = 'output.csv'

  CSV.open(file, 'w') do |writer|
    # Add the header
    writer << ['title', 'isbn', 'date_start_full_text_coverage', 'date_end_full_text_coverage', 'title_url']

    @doc.css('p').each do |record|
      pub_id = record.css('.pub').text

      abstract_url = find_redirect record.css('a/@href')

      title = record.css('a').text
      author = record.css('i').text
      date = (/(January|February|March|April|May|June|July|August|September|October|November|December) \d{4}/).match(record.text)

      # find the ISBN
      abstract_page = Nokogiri::HTML(open(abstract_url))
      abstract_content = abstract_page.css('#content-core')
      isbn = find_isbn(abstract_content)
      line = "#{pub_id} | #{isbn} | #{title} | #{author} | #{date} | #{abstract_url}\n"
      writer << [title, isbn, "1992", "2015", abstract_url]
      puts line
    end

  end
  puts "Finished writing. Everything is in #{file}"
end

main
