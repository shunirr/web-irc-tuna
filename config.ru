#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

$:.unshift './lib', './'
require 'tuna'
require 'yaml'

options = YAML.load(open('config.yaml').read)
Tuna::Web.run! :port => options['web']['port']
