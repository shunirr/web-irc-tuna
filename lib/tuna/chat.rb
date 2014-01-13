# -*- encoding: utf-8 -*-

require 'sinatra'
require 'sinatra/rocketio'
require 'eventmachine'
require 'pit'
require 'groonga'
require 'uri'
require 'json'
require 'irc-string'
require 'net/http'
require 'cgi'
require 'yaml'

module Tuna 
  class Chat < Sinatra::Base
    register Sinatra::RocketIO
    io = Sinatra::RocketIO
    irc = IrcEvent.new
    config = YAML.load(open('config.yaml').read)
    options = config['networks'][0]['network']['settings']
    EM::defer do
      EM.connect(options['host'], options['port'], IrcClient, options, irc)
    end

    configure do
      set :cometio, :timeout => 120, :post_interval => 2, :allow_crossdomain => false
      set :websocketio, :port => 5001
      set :rocketio, :websocket => true, :comet => true

      set :views, File.dirname(__FILE__) + '/../../views'
      set :public_folder, File.dirname(__FILE__) + '/../../public'

      Groonga::Database.open('db/groonga.db')
    end

    io.on :connect do |client|
      puts "connect - <#{client.session}> type:#{client.type} from:#{client.address}"
    end

    io.on :disconnect do |client|
      puts "disconnect - <#{client.session}> type:#{client.type} from:#{client.address}"
    end

    irc.on :privmsg do |msg|
      log = Model::Log.from_message(msg).save
      io.push :privmsg, log.to_json
    end

    get '/chat' do
      haml :index
    end
  end
end

