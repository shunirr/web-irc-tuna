require 'time'

module Tuna::Model
  class Log
    # table.text("command")                  # PRIVMSG
    # table.text("from")                     # shunirr
    # table.text("message")                  # hogehgoe
    # table.time("created_at")               # 12345
    # table.reference("channel", "Channels") # #tuna

    attr_accessor :log

    def initialize(log = {})
      @log = log
      log[:created_at] ||= Time.new.to_i
      if log[:channel].is_a? Channel
        log[:channel] = log[:channel].record
      end
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
