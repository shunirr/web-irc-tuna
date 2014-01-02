#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'net/http'
require 'uri'
require 'celluloid/io'
require 'ircp'
require 'json'
require 'pit'
require 'em-websocket'
require 'irc-string'
require 'cgi'
require 'groonga'

module Tuna
  class IrcClient
    include Celluloid::IO
  
    def initialize(options)
      @host = options[:host]
      @port = options[:port]
      @nick = options[:nick]
      @user = options[:user] || @nick
      @real = options[:real] || @nick
      @pass = options[:pass]
      @ws_port = options[:ws_port]
      @ws_pass = options[:ws_pass]

      @database = Groonga::Database.open('db/groonga.db')
      @network = (Model::Network.find_by_name('default') || Model::Network.new(:name => 'default')).save

      @socket = TCPSocket.new @host, @port
    end
  
    def send(*args)
      msg = Ircp::Message.new(*args)
      case msg.command
      when 'PRIVMSG'
        on_privmsg msg
      when 'NOTICE'
        on_notice msg
      end
      @socket.write msg.to_irc
    end

    def websocket_send(msg)
      if @auth and @websocket
        @websocket.send msg.to_json
      end
    end
  
    def run
      attach
      EM.defer do
        loop do
          @buffer ||= ''
          @buffer << @socket.readpartial(4096)
          while data = @buffer.slice!(/(.+)\r\n/, 1)
            msg = Ircp.parse data
            method = "on_#{msg.command.to_s.downcase}"
            __send__ method, msg if respond_to? method
          end
        end
      end
  
      EM.run do
        EventMachine::WebSocket.start(:host => '0.0.0.0', :port => @ws_port) do |ws|
          @websocket = ws
          ws.onclose do 
            @auth = false
          end
          ws.onmessage do |msg|
            on_websocket_message ws, msg
          end
        end
      end
    end
  
    def on_websocket_message(ws, msg)
      if @auth
        begin
          send *(JSON.parse(msg))
        rescue => e
          puts "#{e} #{msg}"
        end
      else
        @auth = auth msg
        unless @auth
          ws.send '{"error":{"description":"password incorrect"}}'
          # ws.close
        end
      end
    end
  
    def auth(password)
      password == @ws_pass
    end
  
    def attach
      send 'PASS', @pass if @pass
      send 'NICK', @nick
      send 'USER', @user, '*', '*', @real
    end
  
    def on_ping(msg)
      send 'PONG'
    end
  
    def on_privmsg(msg)
      on_message :privmsg, msg
    end
  
    def on_notice(msg)
      on_message :notice, msg
    end

    def on_message(mode, msg)
      channel   = s(msg.params[0])
      body      = CGI.escapeHTML(msg.params[1]) if msg.params[1]
      body_html = html(expand_short_url(body))
      if msg.prefix
        nick = s(msg.prefix.servername || msg.prefix.nick)
      else
        nick = @nick
      end
      c = (Model::Channel.find_by_network_and_name(@network, channel) || Model::Channel.new(:name => channel, :network => @network)).save
      log = Model::Log.new(:command => mode.to_s, :from => nick, :message => body_html, :channel => c).save
      websocket_send log.to_json
    end

    def expand_short_url(str)
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

    def html(str)
      str ||= ''
      str = s(IrcString.parse(str).to_html('irc_'))
      URI.extract(str.dup, %w[http https ftp]){|uri|str.gsub!(uri, %Q{<a href="#{uri}" target="_blank">#{uri}</a>})}
      str
    end

    def images(str)
      images = []
      if str
        URI.extract(str.dup, %w[http https ftp]) do |uri|
          images << uri if uri =~ /\.(jpg|jpeg|gif|png)$/
        end
      end
      images
    end
  
    def s(msg)
      msg.to_s.force_encoding('utf-8')
    end
  end
end
