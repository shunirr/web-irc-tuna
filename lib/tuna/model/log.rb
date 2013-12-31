require 'time'

module Tuna::Model
  class Log
    # table.text("command")                  # PRIVMSG
    # table.text("from")                     # shunirr
    # table.text("message")                  # hogehgoe
    # table.time("created_at")               # 12345
    # table.reference("channel", "Channels") # #tuna

    attr_accessor :log

    def initialize(args = {})
      if args[:record]
        @log = {
          :command    => args[:record].command,
          :from       => args[:record].from,
          :message    => args[:record].message,
          :created_at => args[:record].created_at,
          :channel    => args[:record].channel,
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
      logs = []
      Groonga['Logs'].sort([{:key => 'created_at', :order => :desc}]).each do |record|
        logs << Log.new(:record => record) if record.channel == channel
        break if logs.size >= count
      end
      logs.reverse
    end

    def to_json(*args)
      JSON.generate({
        :command    => @log[:command],
        :from       => @log[:from],
        :message    => @log[:message],
        :created_at => @log[:created_at].to_i,
      })
    end

    def record
      Groonga['Logs'][@id]
    end

    def save
      @id = Groonga['Logs'].add @log
      self
    end
  end
end
