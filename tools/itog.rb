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

#
# this script does a one way synchronization from an iCal calendar to a
# Google calendar
#
# use at your own risk
#

#
# TODO list :
#
#   [x] timezone stuff
#   [x] recurrence
#   [x] use optparser
#   [x] check for stuff removed on the g side
#   [ ] all day events (OK, but 1 day late)
#   [ ] package in gem:bin/ or something like that
#

require 'find'
require 'time'
require 'yaml'
require 'rubygems'
require 'plist' # gem 'plist'
require 'icalendar' # gem 'icalendar'
require 'rufus/gcal' # gem 'rufus-google'

ITOG_VERSION = '0.1.0'

#
# options

opts = ARGV.inject([]) { |a, e|
  t, v = e[0, 1] == '-' ? [ a, [ e ] ] : [ a.last, e ]; t << v; a
}.inject({}) { |h, (k, v)|
  h[k] = v || true; h
} # cheap 5-liner optparse

if opts['--help'] or opts['-h']
  puts %{
  = ruby itog.rb OPTS
  
  pushes a local iCalendar to a google calendar
  
  == command line options

  -v, --version   : print the version of itog.rb and exits
  -h, --help      : print this help text and exits

  mandatory :

  -s, --source n  : specifies the 'source' iCalendar name
  -t, --target n  : specifies the 'target' google calendar name

  optional :

  -c, --caldir d  : specifies the directory 'Calendars'
                    defaults to ~/Library/Calendars/
  }
  exit(0)
end

if opts['--version'] or opts['-v']
  puts "rufus-google itog.rb (ical to gcal) v#{ITOG_VERSION} (MIT license) jmettraux@gmail.com"
  exit(0)
end

SOURCE_ICAL = opts['--source'] || opts['-s'] || 'Test'
TARGET_GCAL = opts['--target'] || opts['-t'] || 'gtest'

CALDIR = opts['--caldir'] || opts['-c'] || "#{ENV['HOME']}/Library/Calendars/"

#
# select target calendar

calendars = Rufus::Google::Calendar.get_calendars(
  :account => ENV['GUSER'], :password => ENV['GPASS'])
GCAL = calendars[TARGET_GCAL]

raise "no calendar named '#{TARGET_GCAL}'" unless GCAL

#
# loads all events in the target calendar
#
# :(  what if there's a shitload of them ?

query = {} # TODO : restrict to a given (opt) timeframe

GCAL_EVENTS = GCAL.events(query).inject({}) { |h, e|
  h[e.entry.id.split('/').last] = e; h
} # is the event id unique ??

puts " .  found #{GCAL_EVENTS.size} events in the '#{TARGET_GCAL}' gcal"

# ical datetime to UTC
#
def adjust_dt (dt)
  return nil unless dt
  dt - DateTime.now.offset
end

# Adds a ical event to the target gcalendar.
# Returns false if the creation failed somehow.
#
def gpost! (ical_event)

  r = ical_event.properties['rrule']
  st = adjust_dt(ical_event.dtstart)
  et = adjust_dt(ical_event.dtend)

  opts = { :title => ical_event.summary }
  opts[:start_time] = st if st and (not r)
  opts[:end_time] = et if et and (not r)

  opts[:all_day] = (ical_event.properties['summary'] == 'ALL DAY')

  if r
    s = ''
    s << "DTSTART:#{st.to_ical}\n" if st
    s << "DTEND:#{et.to_ical}\n" if et
    s << "RRULE:#{r}\n"
    opts[:recurrence] = s
  end

  begin
    GCAL.post!(Rufus::Google::Event.create(opts))
  rescue Exception => e
    puts " !  #{e}"
    #puts e.backtrace
    false
  end
end

# Returns the entry corresponding to the given gcal URI
#
def lookup_entry (gcal_uri)
  GCAL_EVENTS[gcal_uri.split('/').last]
end

# Deletes gcal event with given entry.
# Returns false if deletion failed
#
def gdelete! (gcal_uri)

  gcal_entry = gcal_uri.is_a?(String) ? lookup_entry(gcal_uri) : gcal_uri

  begin
    GCAL.delete!(gcal_entry)
    true
  rescue Exception => e
    puts " !  #{e}"
    false
  end
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
ievents = 0

icses.each do |ics|

  mtime, cal = File.open(events_path + ics) { |f|

    [ f.mtime.gmtime.iso8601, Icalendar.parse(f, true) ]
      # 'true' : assuming one cal per .ics file
  }

  cal.events.each do |e|

    ievents += 1

    summary = "#{e.summary} from #{e.dtstart.to_s} to #{e.dtend.to_s}"

    cached = cache[e.uid]

    on_gcal = cached ? lookup_entry(cached[1]) : false
    gcal_ok = if on_gcal
      pt = on_gcal.entry.published.iso8601
      mt = on_gcal.entry.edited.iso8601
      (pt == mt)
    else
      false
    end

    seen << e.uid

    if cached and cached[0] == mtime and gcal_ok
      puts " .  #{summary}"
      next
    end

    if cached and on_gcal
      puts " -  #{e.summary}"
      unless gdelete!(on_gcal)
        puts  ' !  failed to delete in gcal... skipping for now'
        next
      end
    end

    uri = gpost!(e)

    unless uri
      puts  ' !  failed to add to gcal... skipping for now'
      next
    end

    cache[e.uid] = [ mtime, uri, summary ]

    puts " +  #{summary}"
  end
end

#
# events removed from source

if seen.sort != cache.keys.sort

  not_seen = cache.keys - seen

  not_seen.each do |uid|
    info = cache[uid]
    puts " -  #{info[2]}"
    gdelete!(info[1])
    cache.delete(uid)
  end
end

#
# write cache file

File.open(cache_path, 'w') { |f| f.write(cache.to_yaml) }
#puts "cached in #{cache_path}"

#
# done

puts " .  seen  #{ievents} events in the '#{SOURCE_ICAL}' ical"

