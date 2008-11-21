
#
# Testing rufus-google
#
# Wed Nov 12 20:59:36 JST 2008
#

require 'test/unit'
require 'rubygems'
require 'rufus/gcal'

class Test0Cal < Test::Unit::TestCase

  def test_0

    calendars = Rufus::Google::Calendar.get_calendars(
      :account => ENV['GUSER'], :password => ENV['GPASS'])

    cal = calendars['gtest']

    #cal.events(:q => 'zorglub').each { |e| puts e.entry.to_s }
    #cal.events(:q => 'zorglub').each { |e| puts e.to_s }
    #return
    cal.events(:q => 'zorglub').each { |e| cal.delete!(e) }

    event_id = cal.post_quick!('Tennis with Zorglub November 13 3pm-4:30pm')

    evts = cal.events(:q => 'zorglub')

    assert_equal 1, evts.size

    cal.delete!(evts.first)

    assert_equal [], cal.events(:q => 'zorglub')
  end

end

