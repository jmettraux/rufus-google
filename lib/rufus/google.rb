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
require 'uri'
require 'time'
require 'rufus/verbs'
require 'atom/feed'
#require 'atom/service'
require 'atom/collection'
require 'rufus/ahttp'

module Rufus
module Google

  #
  # Gets an auth token via the Google ClientLogin facility
  #
  def self.get_auth_tokens (options)

    account = options[:account]
    account_type = options[:account_type] || 'GOOGLE'
    password = options[:password]
    service = options[:service] || :cl
    source = options[:source] || "rufus.rubyforge.org-rufus_google-#{VERSION}"

    account = "#{account}@gmail.com" unless account.index('@')

    password = CGI.escape(password)

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

    tokens = r.body.split.inject({}) { |h, l|
      md = l.match(/^(.*)=(.*$)/)
      h[md[1].downcase.to_sym] = md[2]
      h
    }

    options.merge!(tokens)

    tokens
  end

  #
  # Returns the auth token for a google account.
  #
  def self.get_auth_token (options)

    return options if options.is_a?(String)

    options[:auth] || get_auth_tokens(options)[:auth]
  end

  #
  # Returns the redirection location (atom-tools seems not ok with posting
  # and getting redirected so have to use that method)
  #
  def self.get_real_uri (uri, token)

    r = Rufus::Verbs.get(
      uri,
      :headers => { 'Authorization' => "GoogleLogin auth=#{token}" },
      :noredir => true)

    return uri if r.code == '200'

    r['Location']
  end

  #--
  #def self.get_gsessionid (feed_uri, token)
  #  real_uri = get_real_uri(feed_uri, token)
  #  return nil if feed_uri == real_uri
  #  u = URI.parse(real_uri)
  #  query = CGI.unescape(u.query).split('&')
  #  query.each { |param|
  #    k, v = param.split("=")
  #    return v if k == 'gsessionid'
  #  }
  #  nil
  #end
  #++

  #
  # A small method for getting an atom-tools Feed instance.
  # The options hash is a get_auth_token() hash.
  #
  def self.feed_for (feed_uri, options)

    token = get_auth_token(options)

    #uri = get_real_uri(feed_uri, token)
      # no need for that, when 'getting' atom-tools is OK with redirections

    Atom::Feed.new(feed_uri, Rufus::Google::Http.new(token))
  end

  module CollectionMixin

    attr_reader :name, :href

    def initialize (auth_token, entry)

      @token = auth_token
      @name = entry.title.to_s
      @href = entry.links.find { |l| l.rel == 'alternate' }.href
    end

    #
    # Posts (creates) an object
    #
    # Returns the URI of the created resource.
    #
    def post! (o)

      r = collection.post!(o.entry)

      raise "posting object of class #{o.class} failed : #{r.code}" \
        unless r.code.to_i == 201

      r['Location']
    end

    #
    # Removes an object from the collection
    #
    def delete! (o)

      #r = collection.delete!(o.entry, uri)
      #uri = r.code.to_i == 302 ? r['Location'] : nil
      #collection.delete!(o.entry, uri) if uri

      uri = o.is_a?(String) ?  o : o.entry.edit_url
      uri = Rufus::Google.get_real_uri(uri, @token)

      r = collection.delete!(nil, uri)

      raise "failed to delete entry (#{r.code})" unless r.code.to_i == 200

      r
    end

    protected

      #
      # returns the Atom::Collection instance
      #
      def collection

        return @collection if @collection

        uri = Rufus::Google.get_real_uri(href, @token)
        @collection = Atom::Collection.new(uri, Rufus::Google::Http.new(@token))
      end
  end

  #
  # A mixin for entry based objects (like cal events for example)
  #
  module EntryMixin

    attr_reader :entry

    #
    # Creates a google calendar event based on the info found in an
    # atom-tools Entry instance.
    #
    def initialize (entry)
      @entry = entry
    end

    def author
      @entry.authors.first
    end

    def authors
      @entry.authors
    end

    protected

      #
      # fetches a value in the extension part of the entry
      #
      # :time => true will attempt to parse the value to a Time instance
      #
      def evalue (elt_name, att_name, options={})

        v = @entry.extensions.find { |e|
          e.name == elt_name
        }.attribute(att_name)

        return nil unless v

        v = Time.parse(v.value) if options[:time] == true

        v
      end
  end

end
end

