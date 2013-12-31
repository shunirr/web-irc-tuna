# -*- encoding: utf-8 -*-

require 'sinatra'
require 'groonga'

module Tuna
  autoload :Web,       'tuna/web'
  autoload :IrcClient, 'tuna/irc-client'

  module Model
    autoload :Log,       'tuna/model/log'
    autoload :Channel,   'tuna/model/channel'
    autoload :Network,   'tuna/model/network'
  end
end
