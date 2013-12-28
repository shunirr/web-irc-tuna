#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

require 'sinatra'
require 'haml'
require 'pit'

module Setsuna 
  class Web < Sinatra::Base
    set :views, File.dirname(__FILE__) + '/../../views'
    set :public_folder, File.dirname(__FILE__) + '/../../public'

    configure do
      set :pit, Pit.get("setsuna", :require => {
        :ws_host => "WEBSOCKET_HOST",
        :ws_port => "WEBSOCKET_PORT",
      })
    end
    
    get '/' do
      haml :index, :locals => { :url => "ws://#{options.pit[:ws_host]}:#{options.pit[:ws_port]}" }
    end
  end
end

