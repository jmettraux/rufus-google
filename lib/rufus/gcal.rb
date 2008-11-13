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
# John Mettraux
#
# "Made in Japan" as opposed to "Swiss Made"
#
# Wed Nov 12 09:14:09 JST 2008
#

require 'rexml/element'
require 'rufus/google'


module Rufus
module Google

  class Calendar

    include CollectionMixin

    #
    # Returns all the events in the calendar.
    #
    # The query hash can be used to 'query' those events. It currently
    # accepts :q, :start_min and :start_max as keys.
    #
    def events (query={})

      q = query.inject([]) { |a, (k, v)|
        a << "#{k.to_s.gsub(/\_/, '-')}=#{v}"
      }.join("&")

      q = "?#{q}" if q.length > 0

      feed = Rufus::Google.feed_for("#{href}#{q}", @token)
      feed.update!

      feed.entries.collect { |e| Event.new(e) }
    end

    #
    # Posts (creates) a QuickAdd event
    # in this calendar.
    #
    # http://code.google.com/apis/calendar/developers_guide_protocol.html#CreatingQuickAdd
    #
    def post_quick! (event_text)

      post!(Event.create_quick(event_text))
    end

    #
    # Returns a hash calendar_name => calendar
    #
    # an example :
    #
    #   calendars = Rufus::Google::Calendar.get_calendars(
    #     :account => ENV['GUSER'], :password => env['GPASS'])
    #   calendars.values.each { |c| p [ c.name, c.href ] }
    #
    def self.get_calendars (options)

      options[:service] = :cl

      feed = Rufus::Google.feed_for(
        'https://www.google.com/calendar/feeds/default', options)

      feed.update! # fetch the data over the net

      feed.entries.inject({}) { |h, e|
        c = Calendar.new(options[:auth], e)
        h[c.name] = c
        h
      }
    end
  end

  #
  # A google calendar event.
  #
  class Event

    include EntryMixin

    def start_time
      evalue('when', 'startTime', :time => true)
    end

    def end_time
      evalue('when', 'endTime', :time => true)
    end

    def where
      evalue('where', 'valueString')
    end

    def to_s
      {
        :id => @entry.id,
        :title => @entry.title.to_s,
        :start_time => start_time,
        :end_time => end_time,
        :where => where,
        :author => "#{author.name} #{author.email}"
      }.inspect
    end

    def self.create (opts)

      e = Atom::Entry.new
      e.title = opts[:title]
      e.updated!

      if c = opts[:content]
        e.content = c
        e.content['type'] = opts[:type] || 'text'
      end

      if st = opts[:start_time]

        et = opts[:end_time]

        st = st.is_a?(Time) ? st : Time.parse(st)
        et = st.is_a?(Time) ? et : Time.parse(et)

        w = REXML::Element.new('gd:when')
        w.add_attribute('startTime', st.iso8601)
        w.add_attribute('endTime', et.iso8601)

        e.extensions << w
      end

      e.extensions.attributes['xmlns:gd'] =
        'http://schemas.google.com/g/2005'
      e.extensions.attributes['xmlns:gCal'] =
        'http://schemas.google.com/gCal/2005'

      Event.new(e)
    end

    #
    # Creates a QuickAdd event.
    #
    # http://code.google.com/apis/calendar/developers_guide_protocol.html#CreatingQuickAdd
    #
    def self.create_quick (text)

      e = create(
        :title => 'nada',
        :type => 'html',
        :content => text)

      qa = REXML::Element.new('gCal:quickadd')
      qa.add_attribute('value', 'true')
      e.entry.extensions << qa

      e
    end
  end

end
end

