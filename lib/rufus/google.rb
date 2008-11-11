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
# Made in Japan
#
# Tue Nov 11 15:21:44 JST 2008
#

require 'cgi'
require 'rufus/verbs'

module Rufus
module Google

  VERSION = '0.0.1'

  #
  # Gets an auth token via the Google ClientLogin facility
  #
  def self.get_auth_token (options)

    account = options[:account]
    account_type = options[:account_type] || 'GOOGLE'
    password = options[:password]
    service = options[:service] || :cl
    source = options[:source] || "rufus.rubyforge.org-rufus_google-#{VERSION}"

    account = "#{account}@gmail.com" unless account.index('@')

    data = ''
    data << "accountType=#{account_type}&"
    data << "Email=#{account}&"
    data << "Passwd=#{password}&"
    data << "service=#{service}&"
    data << "source=#{source}"

    r = Rufus::Verbs.post(
      'https://www.google.com/accounts/ClientLogin',
      :headers => { 'Content-type' => 'application/x-www-form-urlencoded' },
      :data => data)

    code = r.code.to_i

    raise r.body if code == 403
    raise "not a 200 OK reply : #{code} : #{r.body}" unless code == 200

    r.body.split.find { |l| l.match(/^Auth=.*$/) }[5..-1]
  end

end
end

