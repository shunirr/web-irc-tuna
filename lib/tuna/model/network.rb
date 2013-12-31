
module Tuna::Model
  class Network
    # table.text("name") # freenode.net

    attr_accessor :name

    def initialize(args = {})
      if args[:record]
        @id   = args[:record].id
        @name = args[:record].name
      else
        @name = args[:name]
      end
    end

    def to_json(*args)
      JSON.generate({
        :id   => @id,
        :name => @name,
      })
    end

    def self.find_all
      Groonga['Networks'].map do |record|
        Network.new :record => record
      end
    end

    def self.find_by_id(id)
      network = Groonga['Networks'][id]
      if network
        Network.new(:record => network)
      else
        nil
      end
    end

    def self.find_by_name(name)
      Groonga['Networks'].each do |record|
        if record.name == name
          return Network.new(:record => record)
        end
      end
      nil
    end

    def record
      Groonga['Networks'][@id]
    end

    def save
      data = {:name => @name}
      if @id
        Groonga['Networks'][@id][:name] = @name
      else
        @id = Groonga['Networks'].add data
      end
      self
    end
  end
end
