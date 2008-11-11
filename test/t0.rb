
require 'rubygems'
require 'rufus/google'

print 'account : '
account = gets.strip

print 'password : '
password = gets.strip

puts Rufus::Google.get_auth_token(
  :account => account,
  :password => password,
  :service => :cl)

