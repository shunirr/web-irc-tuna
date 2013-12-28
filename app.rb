#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

require 'sinatra'
require 'haml'
require 'pit'

options = Pit.get("irc", :require => {
  :ws_host => "WEBSOCKET_HOST",
  :ws_port => "WEBSOCKET_PORT",
})

get '/' do
  @ws_url = "ws://#{options[:ws_host]}:#{options[:ws_port]}"
  haml :index
end

