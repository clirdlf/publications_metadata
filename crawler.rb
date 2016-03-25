# -*- coding: utf-8 -*-
require 'open-uri'

require 'nokogiri'

TEST_URL="http://www.clir.org/pubs/reports/pub169"

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

def clean_isbn(isbn)
  parts = isbn.split(' ')
  i = parts[1].gsub('/CLIR/','')
  puts i
end

@doc = Nokogiri::HTML(open(TEST_URL))

content = @doc.css('#content-core')
title = content.css('h3').first.content
editor = content.css('p em, p i').first.content.gsub(/, editor/,'')

meta_block = content.css('p:nth-child(3)').first.content.split('.')
date = meta_block[0].strip!
pages = meta_block[1].gsub(/pp/,'').strip!
cost = meta_block[2].strip!
isbn = meta_block[3].split(' ')[1].gsub(/CLIR/,'')

url = content.css('p:nth-child(4) a/@href')
puts url
