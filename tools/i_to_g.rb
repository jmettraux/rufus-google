
require 'find'
require 'rubygems'
require 'plist' # gem 'plist'
require 'icalendar' # gem 'icalendar'

FROM = 'Test'

plist_path = nil

Find.find("#{ENV['HOME']}/Library/Calendars/") do |path|
  if path.match(/\.plist$/)
    pl = Plist.parse_xml(path)
    if pl['Title'] == FROM
      plist_path = path
      break
    end
  end
end

events_path = "#{File.dirname(plist_path)}/Events/"
icss = Dir.entries(events_path).select { |fn| fn.match(/\.ics$/) }
icss = icss.collect { |fn| "#{events_path}/#{fn}" }

events = []

events = icss.inject([]) do |a, ics|
  cal = File.open(ics) { |f| Icalendar.parse(f, true) }
  a = a + cal.events
end

p events

e = events.first
puts
#puts e.name
puts e.summary
puts e.dtstart
puts e.dtend

