
require 'rubygems'
require 'rufus/gcal'

calendars = Rufus::Google::Calendar.get_calendars(
  :account => ENV['GUSER'], :password => ENV['GPASS'])

#calendars.values.each { |c| p [ c.name, c.href ] }

cal = calendars['gtest']

#id = cal.post_quick!('Tennis with John November 13 3pm-4:30pm')
#t = Time.now
#id = cal.post!(Rufus::Google::Event.create(
#  :title => 'drink Tequila at the Tennis club',
#  :start_time => t,
#  :end_time => t + 3600))

#cal.events(:q => 'tennis').each do |e|
cal.events().each do |e|
  puts
  puts e.to_s
  puts e.entry.to_s.gsub(/</, "\n<")
  #cal.delete!(e)
end
#cal.delete!(id)

#puts "#{cal.events(:q => 'tennis').size} tennis events"

