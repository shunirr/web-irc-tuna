require 'time'
require 'uuidtools'

module Tuna::Model
  class Log
    # table.text("uuid")
    # table.text("command")                  # PRIVMSG
    # table.text("from")                     # shunirr
    # table.text("message")                  # hogehgoe
    # table.time("created_at")               # 12345
    # table.reference("channel", "Channels") # #tuna

    attr_accessor :log

    def initialize(args = {})
      if args[:record]
        @id = args[:record].id
        @log = {
          :command    => args[:record].command,
          :from       => args[:record].from,
          :message    => args[:record].message,
          :created_at => args[:record].created_at,
          :channel    => args[:record].channel,
          :uuid       => args[:record].uuid,
        }
      else
        @log = args
        @log[:created_at] ||= Time.new.to_i
        if @log[:channel].is_a? Channel
          @log[:channel] = @log[:channel].record
        end
      end
    end

    def self.find_by_channel(channel, args = {})
      if channel.is_a? Channel
        channel = channel.record
      end
      count = args[:count] || 10
      offset = args[:offset]
      logs = []
      start = (offset) ? false : true
      Groonga['Logs'].sort([{:key => 'created_at', :order => :desc}]).each do |record|
        if start
          logs << Log.new(:record => record) if record.channel == channel
        else
          start = record.uuid == offset
        end
        break if logs.size >= count
      end
      logs.reverse
    end

    def self.from_message(msg)
      channel   = Tuna::Util.s(msg.params[0])
      body      = CGI.escapeHTML(msg.params[1]) if msg.params[1]
      body_html = Tuna::Util.html(Tuna::Util.expand_short_url(body))
      if msg.prefix
        nick = Tuna::Util.s(msg.prefix.servername || msg.prefix.nick)
      else
        nick = @nick
      end
      network = Network.find_by_name('default')
      unless network
        network = Network.new(:name => 'default').save
      end
      c = Channel.find_by_network_and_name(network, channel)
      unless c
        c = Channel.new(:name => channel, :network => network).save
      end
      Log.new(:command => msg.command.to_s.downcase, :from => nick, :message => body_html, :channel => c)
    end

    def to_json(*args)
      JSON.generate({
        :uuid       => @log[:uuid],
        :command    => @log[:command],
        :from       => @log[:from],
        :message    => @log[:message],
        :created_at => @log[:created_at].to_i,
        :channel    => Channel.new(:record => @log[:channel]),
      })
    end

    def record
      Groonga['Logs'][@id]
    end

    def save
      @log[:uuid] = UUIDTools::UUID.random_create.to_s unless @log[:uuid]
      @id = Groonga['Logs'].add(@log).id
      self
    end
  end
end
