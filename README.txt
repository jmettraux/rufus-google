
= rufus-google

rufus-google should probably be named "rufus-gcal" for now, as only google calendar stuff is implemented.

This gem leverages 'atom-tools' to play with Google Data APIs.

The only authentication mechanism implemented for now is "ClientLogin".

(There is a one way synchronization tool for ical to gcal at

  http://github.com/jmettraux/rufus-google/tree/master/tools/itog.rb

work in progress...)


== getting it

  sudo gem install rufus-google

or at

http://rubyforge.org/frs/?group_id=4812


== usage

Using Google Calendar :

    require 'rubygems'
    require 'rufus/gcal'

    calendars = Rufus::Google::Calendar.get_calendars(
      :account => ENV['GUSER'], :password => ENV['GPASS'])

    #calendars.values.each { |c| p [ c.name, c.href ] }

    cal = calendars['gwork']

    event_id = cal.post_quick!('Tennis with John November 13 3pm-4:30pm')

    cal.events(:q => 'tennis').each do |e|
      puts
      puts e.to_s
    end

    cal.delete!(event_id)

    puts "#{cal.events(:q => 'tennis').size} tennis events"


Other Google APIs will be covered later, if the need arise.


== dependencies

the 'rufus-verbs' and the 'atom-tools' gems.


== mailing list

On the rufus-ruby list[http://groups.google.com/group/rufus-ruby] :

    http://groups.google.com/group/rufus-ruby


== issue tracker

http://rubyforge.org/tracker/?atid=18584&group_id=4812&func=browse


== irc

irc.freenode.net #ruote


== source

http://github.com/jmettraux/rufus-google

  git clone git://github.com/jmettraux/rufus-google.git


== author

John Mettraux, jmettraux@gmail.com 
http://jmettraux.wordpress.com


== the rest of Rufus

http://rufus.rubyforge.org


== license

MIT

