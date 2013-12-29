#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

$:.unshift './lib', './'
require 'pit'
require 'tuna'

options = Pit.get("tuna", :require => {
  :host => "IRC_HOST",
  :port => "IRC_PORT",
  :nick => "IRC_NICK",
  :pass => "IRC_PASS",
  :ws_port  => "WEBSOCKET_PORT",
  :ws_pass  => "WEBSOCKET_PASSWORD",
})

client = Tuna::IrcClient.new options
client.run

