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

    def name
      @entry.title.to_s
    end

    def href
      @entry.links.find { |l| l.rel == 'alternate' }.href
    end

    def post! (event)

      uri = Rufus::Google.get_real_uri(href, @token)

      c = Atom::Collection.new(uri, Rufus::Google::Http.new(@token))
      r = c.post!(event.entry)

      raise "posting event failed : #{r.code}" unless r.code.to_i == 201

      r['Location']
    end

    def post_quick! (event_text)

      post!(Event.new_quick(event_text))
    end

    #
    # returns a hash calendar_name => calendar
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

  class Event

    attr_reader :entry

    def initialize (opts)

      @entry = Atom::Entry.new
      @entry.title = opts[:title] || 'no-title'
      @entry.updated!
      @entry.content = opts[:content]
      @entry.content['type'] = opts[:type]

      @entry.extensions.attributes['xmlns:gCal'] =
        'http://schemas.google.com/gCal/2005'
    end

    def self.new_quick (text)

      e = Event.new(
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

