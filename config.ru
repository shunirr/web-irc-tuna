#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

$:.unshift './lib', './'
require 'tuna'
require 'pit'

options = Pit.get("tuna", :require => {
  :web_port  => "WEBSOCKET_PORT"
})

Tuna::Web.run! :port => options[:web_port]

