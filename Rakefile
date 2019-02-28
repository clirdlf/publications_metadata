# frozen_string_literal: true

# system gems
require 'csv'
require 'open-uri'
require 'net/http'
require 'time'

# other
require 'chronic'
require 'colorize'
require 'nokogiri'

BASE_URL = 'http://www.clir.org/pubs/reports'.freeze
PUBLISHER = 'Council on Library and Information Resources'.freeze

# Minimum Fields
# 1.       Title name
# 2.       Print ISSN (Print ISSNs are preferable; if these are not available, please include eISSNs.)
# 3.       Date start of full-text coverage
# 4.       Date end of full-text coverage
# 5.       Title-level URL
# 6.       Embargo (if applicable)

# KBART Fields
# date_last_issue_online
# num_last_vol_online
# num_last_issue_online
# title_url
# first_author
# title_id
# embargo_info
# coverage_depth
# coverage_notes
# publisher_name

task default: %(metadata:all)

def clean_isbn(isbn)
  parts = isbn.split(' ')
  parts[1].gsub('/CLIR/', '')
end

def get_data(url)
  Nokogiri::HTML(URI.open(url))
end

def add_header(csv)
  csv << %w[
    title_id
    publication_title
    print_identifier
    first_editor
    date_monograph_published_online
    date_monograph_published_print
    title_url
  ]
end

def find_redirect(uri)
  res = Net::HTTP.get_response(URI(uri.to_s))
  res['location'] = uri if res['location'].nil?
  res['location']
end

def find_pub(string)
  /pub[\d]+/.match(string.to_s)
end

def find_isbn(string)
  /ISBN\x20\d{1,5}([- ])\d{1,7}\1\d{1,6}\1(\d{1,6}|X)(\1\d)?/.match(string.to_s)
end

namespace :metadata do
  desc 'Generate metadata for vendor crawls'
  task all: %(kbart)

  desc 'Generate KBART metadata'
  task :kbart do
    filedate = Time.now.strftime('%Y-%m-%d')
    filename = "metadata/CLIR_Global_AllTitles_#{filedate}.csv".freeze

    puts "Fetching #{BASE_URL}".green
    @doc = get_data(BASE_URL)

    CSV.open(filename, 'wb') do |csv|
      add_header(csv)

      @doc.css('#publications//p').each do |record|
        # title_id = record.css('.pub').text # find this
        title_id = find_pub(record)
        title = record.css('a').text
        editors = record.css('i,em').text.gsub('/, editor/', '').gsub('/by /', '')
        first_editor = editors.split(/(and|,)/).first

        date = /(January|February|March|April|May|June|July|August|September|October|November|December) \d{4}/.match(record.text)
        formatted_date = Chronic.parse(date).strftime('%Y-%m') unless date.nil?

        # find the ISBN
        puts "\tFetching abstract for #{title}".green
        abstract_url = record.xpath('a/@href').text

        unless abstract_url.nil?
          abstract_page = get_data(abstract_url)
          abstract_content = abstract_page.css('.entry-content')
          isbn = find_isbn(abstract_content).to_s.gsub(/ISBN /, '')
          # line = "#{title_id} | #{title} | #{isbn} | #{first_editor} | #{formatted_date} | #{date} | #{abstract_url}\n"
          csv << [title_id, title, isbn, first_editor, formatted_date, formatted_date, abstract_url]
        end


      end
    end

    puts "Finishing writing KBART formatted metadata. Look in #{filename}.".green
  end
end
