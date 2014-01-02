#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

require 'sinatra'
require 'sinatra/json'
require 'haml'
require 'pit'
require 'groonga'

module Tuna 
  class Web < Sinatra::Base
    # use Login

    configure do
      set :views, File.dirname(__FILE__) + '/../../views'
      set :public_folder, File.dirname(__FILE__) + '/../../public'

      Groonga::Database.open('db/groonga.db')
      set :pit, Pit.get("tuna", :require => {
        :ws_host => "WEBSOCKET_HOST",
        :ws_port => "WEBSOCKET_PORT",
      })
    end
    
    get '/' do
      haml :index, :locals => { :url => "ws://#{options.pit[:ws_host]}:#{options.pit[:ws_port]}" }
    end
    
    get '/api/v1/networks' do
      content_type :json
      Model::Network.find_all.to_json
    end

    get '/api/v1/networks/:id/channels' do
      content_type :json
      id = params[:id].to_i
      network = Model::Network.find_by_id(id)
      Model::Channel.find_by_network(network).to_json
    end

    get '/api/v1/channels/:id/logs' do
      content_type :json
      id = params[:id].to_i
      count  = (params[:count] || '10').to_i
      offset = params[:offset]
      channel = Model::Channel.find_by_id(id)
      Model::Log.find_by_channel(channel, :count => count, :offset => offset).to_json
    end
  end
end

