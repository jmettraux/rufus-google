
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

# use at your own risk

#
# TODO list :
#
#   [ ] timezone stuff
#

require 'find'
require 'time'
require 'yaml'
require 'rubygems'
require 'plist' # gem 'plist'
require 'icalendar' # gem 'icalendar'
require 'rufus/gcal' # gem 'rufus-google'

SOURCE_ICAL = 'Test'
TARGET_GCAL = 'gtest'

CALDIR = "#{ENV['HOME']}/Library/Calendars/"

#
# select target calendar

calendars = Rufus::Google::Calendar.get_calendars(
  :account => ENV['GUSER'], :password => ENV['GPASS'])
GCAL = calendars[TARGET_GCAL]

raise "no calendar named '#{TARGET_GCAL}'" unless GCAL

# Adds a ical event to the target gcalendar.
# Returns false if the creation failed somehow.
#
def gpost! (ical_event)
end


# Deletes gcal event with given uri.
# Returns false if deletion failed
#
def gdelete! (gcal_uri)
  GCAL.delete!(gcal_uri) rescue return false
  true
end

#
# locate source calendar

plist_path = nil

Find.find(CALDIR) do |path|
  if path.match(/\.plist$/)
    pl = Plist.parse_xml(path)
    if pl['Title'] == SOURCE_ICAL
      plist_path = path
      break
    end
  end
end

cal_path = File.dirname(plist_path)
events_path = "#{cal_path}/Events/"

#
# [re]load cache : itog.yaml

cache_path = "#{cal_path}/itog.yaml"
cache = File.exist?(cache_path) ? YAML.load(File.read(cache_path)) : {}

#
# establish list of .ics files

icses = Dir.entries(events_path).select { |fn| fn.match(/\.ics$/) }

#
# treat each event

seen = []

icses.each do |ics|

  mtime, cal = File.open(events_path + ics) { |f|

    [ f.mtime.iso8601, Icalendar.parse(f, true) ]
      # 'true' : assuming one cal per .ics file
  }

  cal.events.each do |e|

    summary = "#{e.summary} from #{e.dtstart.to_s} to #{e.dtend.to_s}"

    cached = cache[e.uid]

    if cached and cached[0] == mtime
      puts " . already seen : #{summary}"
      seen << e.uid
      next
    end

    if cached
      puts " : deleting     : #{summary}"
      #gcal.delete!(cached[1])
    end

    #uri = gcal.post!(Rufus::Google::Event.new())
    uri = 'goog-uri'

    cache[e.uid] = [ mtime, uri, summary ]
    seen << e.uid

    puts " * added          : #{summary}"
  end
end

#
# events removed from source

if seen.sort != cache.keys.sort

  not_seen = cache.keys - seen

  not_seen.each do |uid|
    info = cache[uid]
    puts " : deleting       : #{info[2]}"
    #gcal.delete!(info[1])
    cache.delete(uid)
  end
end

#
# write cache file

File.open(cache_path, 'w') { |f| f.write(cache.to_yaml) }
#puts "cached in #{cache_path}"

