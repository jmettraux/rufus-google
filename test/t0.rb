
require 'rubygems'
require 'rufus/gcal'

calendars = Rufus::Google::Calendar.get_calendars(
  :account => ENV['GUSER'], :password => ENV['GPASS'])

#calendars.values.each { |c| p [ c.name, c.href ] }

cal = calendars['ghome']

puts cal.post_quick!('Tennis with John November 13 3pm-4:30pm')

