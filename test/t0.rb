
require 'rubygems'
require 'rufus/gcal'

calendars = Rufus::Google::Calendar.get_calendars(
  :account => ENV['GUSER'], :password => ENV['GPASS'])

#calendars.values.each { |c| p [ c.name, c.href ] }

cal = calendars['gwork']

event = cal.post_quick!('Tennis with John November 13 3pm-4:30pm')

cal.events(:q => 'tennis').each do |e|
  puts
  puts e.to_s
end

cal.delete!(event)

puts "#{cal.events(:q => 'tennis').size} tennis events"

