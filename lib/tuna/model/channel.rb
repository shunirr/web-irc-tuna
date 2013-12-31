require 'json'

module Tuna::Model
  class Channel

    # table.text("name")
    # table.text("topic")
    # table.reference("network", "Networks") # freenode

    attr_accessor :id, :name, :network, :topic

    def initialize(args = {})
      if args[:record]
        @name    = args[:record].name
        @network = Network.new(:record => args[:record].network)
        @topic   = args[:record].topic || ''
        @id      = args[:record].id
      else
        @name    = args[:name]
        @network = args[:network]
        @topic   = args[:topic] || ''
      end
    end

    def to_json(*args)
      JSON.generate({
        :id => @id,
        :name => @name,
        :topic => @topic,
      })
    end

    def record
      Groonga['Channels'][@id]
    end

    def self.find_by_network_and_name(network, name)
      if network.is_a? Network
        network = network.record
      end
      Groonga['Channels'].each do |record|
        if record.network == network and record.name == name
          return Channel.new(:record => record)
          break
        end
      end
      nil
    end

    def self.find_by_id(id)
      channel = Groonga['Channels'][id]
      if channel
        Channel.new(:record => channel)
      else
        nil
      end
    end

    def self.find_all
      channels = []
      Groonga['Channels'].each do |record|
        channels << record
      end
      channels.map{|c| Channel.new(:record => c)}
    end

    def self.find_by_network(network)
      if network.is_a? Network
        network = network.record
      end
      channels = []
      Groonga['Channels'].each do |record|
        channels << record if record.network == network
      end
      channels.map{|c| Channel.new(:record => c)}
    end

    def save
      if @id
        Groonga['Channels'][@id][:name]    = @name
        Groonga['Channels'][@id][:network] = @network.record
        Groonga['Channels'][@id][:topic]   = @topic
      else
        @id = Groonga['Channels'].add(:name => @name, :network => @network.record, :topic => @topic)
      end
      self
    end
  end
end
