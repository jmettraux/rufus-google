
#
#--
# Copyright (c) 2008, John Mettraux, jmettraux@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# (MIT license)
#++
#

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

