#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'celluloid/io'
require 'ircp'
require 'json'
require 'pit'
require 'em-websocket'
require 'irc-string'
require 'cgi'

module Setsuna
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
  
      @socket = TCPSocket.new @host, @port
    end
  
    def send(*args)
      msg = Ircp::Message.new(*args)
      puts "SEND: #{msg}"
      @socket.write msg.to_irc
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
          ws.send 'password incorrect'
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
      if msg.prefix
        on_channel_talk :privmsg, msg
      else
        on_private_talk :privmsg, msg
      end
    end
  
    def on_notice(msg)
      if msg.prefix
        on_channel_talk :notice, msg
      else
        on_private_talk :notice, msg
      end
    end
  
    def on_private_talk(mode, msg)
      from = msg.params[0]
      body = CGI.escapeHTML(msg.params[1])
      data = {
          :from => {
            :type => 'user',
            :id => s(from),
          },
          :images => images(body),
          :mode => mode,
          :body => html(body),
          :time => Time.now.to_i,
      }
      puts data
      @websocket.send data.to_json if @auth and @websocket
    end
  
    def on_channel_talk(mode, msg)
      channel = msg.params[0]
      body    = CGI.escapeHTML(msg.params[1])
      data = {
          :from => {
            :type => 'channel',
            :channel => s(channel),
            :id => s(msg.prefix.servername || msg.prefix.nick),
          },
          :images => images(body),
          :mode => mode,
          :body => html(body),
          :time => Time.now.to_i,
      }
      puts data
      @websocket.send data.to_json if @auth and @websocket
    end

    def html(str)
      str = s(IrcString.parse(str).to_html('irc_'))
      URI.extract(str.dup, %w[http https ftp]){|uri|str.gsub!(uri, %Q{<a href="#{uri}" target="_blank">#{uri}</a>})}
      str
    end

    def images(str)
      images = []
      URI.extract(str.dup, %w[http https ftp]) do |uri|
        images << uri if uri =~ /\.(jpg|jpeg|gif|png)$/
      end
      images
    end
  
    def s(msg)
      msg.to_s.force_encoding('utf-8')
    end
  end
end
