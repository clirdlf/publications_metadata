# -*- coding: utf-8 -*-
# frozen_string_literal: true
require 'open-uri'
require 'net/http'
require 'csv'
require 'time'

require 'nokogiri'
require 'chronic'

BASE_URL = 'http://www.clir.org/pubs/reports'.freeze
PUBLISHER = 'Council on Library and Information Resources'.freeze

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
  /ISBN\x20\d{1,5}([- ])\d{1,7}\1\d{1,6}\1(\d{1,6}|X)(\1\d)?/.match(string.to_s)
end

def add_header(writer)
  writer << %w(
    title_id
    publication_title
    print_identifier
    first_editor
    date_monograph_published_online
    date_monograph_published_print
    title_url
  )
end

def main
  filedate = Time.now.strftime('%Y-%m-%d')
  file = "CLIR_Global_AllTitles_#{filedate}.csv"

  CSV.open(file, 'w') do |writer|
    # Add the header
    add_header(writer)

    @doc.css('p').each do |record|
      title_id = record.css('.pub').text

      abstract_url = find_redirect record.css('a/@href')

      title = record.css('a').text
      editors = record.css('i, em').text.gsub(/, editor/,'').gsub(/by /, '')
      first_editor = editors.split(/(and|,)/).first

      date = /(January|February|March|April|May|June|July|August|September|October|November|December) \d{4}/.match(record.text)
      formatted_date = Chronic.parse(date).strftime('%Y-%m')

      # find the ISBN
      abstract_page = Nokogiri::HTML(open(abstract_url))
      abstract_content = abstract_page.css('#content-core')
      isbn = find_isbn(abstract_content).to_s.gsub(/ISBN /, '')
      line = "#{title_id} | #{title} | #{isbn} | #{first_editor} | #{formatted_date} | #{date} | #{abstract_url}\n"
      writer << [title_id, title, isbn, first_editor, formatted_date, formatted_date, abstract_url]
      puts line
    end
  end
  puts "Finished writing. Everything is in #{file}"
end

main
