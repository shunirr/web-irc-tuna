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

module Tuna 
  class Chat < Sinatra::Base
    register Sinatra::RocketIO
    io = Sinatra::RocketIO
    irc = IrcEvent.new

    options = Pit.get('tuna')
    EM::defer do
      EM.connect(options[:host], options[:port], IrcClient, options, irc)
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
      channel   = Util.s(msg.params[0])
      body      = CGI.escapeHTML(msg.params[1]) if msg.params[1]
      body_html = Util.html(Util.expand_short_url(body))
      if msg.prefix
        nick = Util.s(msg.prefix.servername || msg.prefix.nick)
      else
        nick = @nick
      end
      network = Model::Network.find_by_name('default')
      unless network
        network = Model::Network.new(:name => 'default').save
      end
      c = Model::Channel.find_by_network_and_name(network, channel)
      unless c 
        c = Model::Channel.new(:name => channel, :network => network).save
      end
      log = Model::Log.new(:command => msg.command.to_s.downcase, :from => nick, :message => body_html, :channel => c).save
      io.push :privmsg, log.to_json
    end

    get '/chat' do
      haml :index
    end
  end
end

