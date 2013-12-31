
module Tuna::Model
  class Channel

    # table.text("name")
    # table.text("topic")
    # table.reference("network", "Networks") # freenode

    attr_accessor :name, :network, :topic

    def initialize(args = {})
      if args[:record]
        @name    = args[:record].name
        @network = args[:record].network
        @topic   = args[:record].topic || ''
        @id      = args[:record].key
      else
        @name    = args[:name]
        @network = args[:network]
        @topic   = args[:topic] || ''
        record = find_record(@network, @name)
        if record
          @id = record.key
        end
      end
    end

    def record
      Groonga['Channels'][@id]
    end

    def self.find_all
      channels = []
      Groonga['Channels'].each do |record|
        channels << record
      end
      channels.map{|c| Channel.new(:record => c)}
    end

    def self.find_by_network(network)
      channels = []
      Groonga['Channels'].each do |record|
        channels << record if record.network == network
      end
      channels.map{|c| Channel.new(:record => c)}
    end

    def save
      data = {:name => @name, :network => @network.record, :topic => @topic}
      p data
      if @id
        Groonga['Channels'][@id] = data
      else
        @id = Groonga['Channels'].add(data)
      end
      self
    end

    private
    def find_record(network, name)
      channel = nil
      Groonga['Channels'].each do |record|
        if record.network == network and record.name == name
          channel = record
          break
        end
      end
      channel
    end
  end
end
