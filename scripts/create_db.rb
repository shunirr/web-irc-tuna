#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

require 'groonga'

Groonga::Database.create(:path => 'db/groonga.db')
Groonga::Schema.define do |schema|  
  schema.create_table("Networks", :type => :array) do |table|
    table.text("name")
  end

  schema.create_table("Channels", :type => :array) do |table|
    table.text("name")
    table.text("topic")
    table.reference("network", "Networks") # freenode
  end

  schema.create_table("Logs", :type => :array) do |table|
    table.text("uuid")                     # UUID
    table.text("command")                  # PRIVMSG
    table.text("from")                     # shunirr
    table.text("message")                  # hogehgoe
    table.time("created_at")               # 12345
    table.reference("channel", "Channels") # #tuna
  end

  schema.create_table("Terms",
                      :type => :patricia_trie,
                      :key_type => "ShortText",
                      :default_tokenizer => "TokenBigram",
                      :key_normalize => true) do |table|
    table.index("Logs.message")
  end
end
