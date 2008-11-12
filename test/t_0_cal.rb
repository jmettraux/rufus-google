
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

    cal = calendars['gwork']

    event_id = cal.post_quick!('Tennis with Zorglub November 13 3pm-4:30pm')

    assert_equal 1, cal.events(:q => 'zorglub').size

    cal.delete!(event_id)

    assert_equal [], cal.events(:q => 'zorglub')
  end

end

