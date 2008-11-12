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

require 'rufus/google'


module Rufus
module Google

  class Calendar

    def initialize (auth_token, entry)

      @token = auth_token
      @entry = entry
    end

    #
    # The name of the calendar.
    #
    def name
      @entry.title.to_s
    end

    #
    # The URI of the calendar.
    #
    def href
      @entry.links.find { |l| l.rel == 'alternate' }.href
    end

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

    def collection

      return @collection if @collection

      uri = Rufus::Google.get_real_uri(href, @token)
      @collection = Atom::Collection.new(uri, Rufus::Google::Http.new(@token))
    end

    #
    # Posts (creates) an event in this calendar.
    #
    def post! (event)

      r = collection.post!(event.entry)

      raise "posting event failed : #{r.code}" unless r.code.to_i == 201

      r['Location']
    end

    #
    # Removes an event from the calendar.
    #
    def delete! (event)

      entry = event.is_a?(Event) ? event.entry : event
      entry, uri = case event
        when Event then [ event.entry, event.entry.edit_url ]
        when Atom::Entry then [ event, event.edit_url ]
        else [ nil, event ]
      end

      collection.delete!(entry, uri)
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
      extension_value('when', 'startTime')
    end

    def end_time
      extension_value('when', 'endTime')
    end

    def where
      extension_value('where', 'valueString')
    end

    def to_s
      {
        :id => @entry.id,
        :title => @entry.title.to_s,
        :start_time => start_time,
        :end_time => end_time,
        :where => where
      }.inspect
    end

    def self.create_event (opts)

      e = Atom::Entry.new
      e.title = opts[:title] || 'no-title'
      e.updated!
      e.content = opts[:content]
      e.content['type'] = opts[:type]

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

      e = create_event(
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

