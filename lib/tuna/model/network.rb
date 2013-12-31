
module Tuna::Model
  class Network
    # table.text("name") # freenode.net

    attr_accessor :name

    def initialize(args = {})
      if args[:record]
        @id   = args[:record].key
        @name = args[:record].name
      else
        @name = args[:name]
      end
    end

    def self.find_all
      networks = []
      Groonga['Networks'].each do |record|
        networks << record
      end
      networks.map{|r| Network.new(:record => r)}
    end

    def self.find_by_name(name)
      network = nil
      Groonga['Networks'].each do |record|
        if record.name == name
          network = record
          break
        end
      end
      if network
        Network.new(:record => network)
      else
        nil
      end
    end

    def record
      Groonga['Networks'][@id]
    end

    def save
      data = {:name => @name}
      if @id
        Groonga['Networks'][@id] = data
      else
        @id = Groonga['Networks'].add data
      end
      self
    end
  end
end
