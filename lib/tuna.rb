# -*- encoding: utf-8 -*-

require 'sinatra'
require 'groonga'

module Tuna
  autoload :Web,       'tuna/web'
  autoload :Login,     'tuna/login'
  autoload :Chat,      'tuna/chat'
  autoload :IrcClient, 'tuna/irc-client'
  autoload :IrcEvent,  'tuna/irc-event'
  autoload :Util,      'tuna/util'

  module Model
    autoload :Log,       'tuna/model/log'
    autoload :Channel,   'tuna/model/channel'
    autoload :Network,   'tuna/model/network'
  end
end
