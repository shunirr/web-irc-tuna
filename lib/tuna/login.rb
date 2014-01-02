#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

require 'sinatra'

module Tuna 
  class Login < Sinatra::Base
    configure do
      enable :sessions
      set :pit, Pit.get("tuna", :require => {
        :ws_pass => "WEBSOCKET_PASSWORD",
      })
    end

    get '/login' do
      content_type :html
      status 200
      "<form action='/login' method='POST'><input type='password' name='password'><input type='submit' value='login'></form>"
    end
  
    post '/login' do
      if params[:password] = options.pit[:ws_pass]
        session['username'] = 'default'
        redirect '/'
      else
        status 401
        ''
      end
    end

    before do
      if request.path_info != '/login' && !session['username']
        halt 401, "Access denied, please <a href='/login'>login</a>."
      end
    end
  end
end

