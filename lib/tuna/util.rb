# -*- coding: utf-8 -*-

require 'uri'
require 'net/http'
require 'irc-string'

module Tuna
  class Util
    def self.expand_short_url(str)
      str ||= ''
      URI.extract(str.dup, %w[http https]) do |u|
        uri = URI.parse u
        if uri.host == 't.co'
          begin
            response = Net::HTTP.get_response uri
            str.gsub!(u, response['location']) if response['location']
          rescue => e
          end
        end
      end
      str
    end

    def self.html(str)
      str ||= ''
      str = s(IrcString.parse(str).to_html('irc_'))
      URI.extract(str.dup, %w[http https ftp]) do |uri|
        str.gsub!(uri, %Q{<a href="#{uri}" target="_blank">#{uri}</a>})
      end
      str
    end
    
    def self.s(msg)
      msg.to_s.force_encoding('utf-8')
    end
  end
end
