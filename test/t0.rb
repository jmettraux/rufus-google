
require 'rubygems'
require 'rexml/document'
require 'rufus/google'

account = ENV['GUSER']
password = ENV['GPASS']

token = Rufus::Google.get_auth_token(
  :account => account,
  :password => password,
  :service => :cl)

#puts Rufus::Google.get_real_url(
#  'https://www.google.com/calendar/feeds/default/owncalendars/full', token)

#feed = Rufus::Google.feed_for(
#  #'https://www.google.com/calendar/feeds/default/owncalendars/full',
#  'http://www.google.com/calendar/feeds/default/owncalendars/full',
#  :account => account,
#  :password => password,
#  :service => :cl)
#
#feed.update!
#
##p feed
##feed.links.each { |l| p l }
##p feed.entries
#feed.entries.each do |e|
#  puts
#  e.links.each do |l|
#    puts " - #{l.base}"
#    puts "   href: #{l.href}"
#    puts "   rel: #{l.rel}"
#    puts "   type: #{l.type}"
#  end
#end

coll = Rufus::Google.collection_for(
  'http://www.google.com/calendar/feeds/default/owncalendars/full',
  :account => account,
  :password => password,
  :service => :cl)

e = Atom::Entry.new
e.title = 'tenis la menace'
e.updated!
e.content = 'Tennis with John November 12 3pm-3:30pm'
e.content['type'] = 'html'
qa = REXML::Element.new('gCal:quickadd')
qa.add_attribute('value', 'true')
e.extensions << qa
e.extensions.attributes['xmlns:gCal'] = 'http://schemas.google.com/gCal/2005'

#puts e.to_xml.to_s

res = coll.post!(e)

p res.code
puts
puts res.read_body

