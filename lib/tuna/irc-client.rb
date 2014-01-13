# -*- coding: utf-8 -*-

require 'ircp'
require 'pit'
require 'eventmachine'

module Tuna
  class IrcClient < EM::Connection
    def initialize(options, event)
      @nick = options[:nick]
      @user = options[:user] || @nick
      @real = options[:real] || @nick
      @pass = options[:pass]
      @event = event
#      @event.on :privmsg do |msg|
#        puts msg.to_s
#      end
    end
  
    def send(*args)
      msg = Ircp::Message.new(*args)
      case msg.command
      when 'PRIVMSG'
        on_privmsg msg
      when 'NOTICE'
        on_notice msg
      end
      send_data msg.to_irc
    end
  
    def post_init
      send 'PASS', @pass if @pass
      send 'NICK', @nick
      send 'USER', @user, '*', '*', @real
    end
  
    def unbind
    end
  
    def receive_data(data)
      msg = Ircp.parse data
      method = "on_#{msg.command.to_s.downcase}"
      __send__ method, msg
    end
  
    def on_ping(msg)
      send 'PONG'
    end

    def method_missing(name, msg)
      if name.to_s =~ /^on_(\w+)$/
        @event.emit :"#{$1}", msg if @event
      else
        super
      end
    end
  end
end
