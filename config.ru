#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

$:.unshift './lib', './'
require 'setsuna'
require 'pit'

options = Pit.get("setsuna", :require => {
  :web_port  => "WEBSOCKET_PORT"
})

Setsuna::Web.run! :port => options[:web_port]

