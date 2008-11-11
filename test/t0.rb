
require 'rubygems'
require 'rexml/document'
require 'rufus/google'

account = ENV['GUSER']
password = ENV['GPASS']

token = Rufus::Google.get_auth_token(
  :account => account,
  :password => password,
  :service => :cl)

puts Rufus::Google.get_real_url(
  'https://www.google.com/calendar/feeds/default/owncalendars/full', token)

