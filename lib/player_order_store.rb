require "forwardable"
require "singleton"
require "yaml"
require "yaml/store"

class PlayerOrderStore
  include Singleton

  class << self
    extend Forwardable
    def_delegators :instance, :get, :set
  end

  def initialize
    @db = YAML::Store.new "player_order.store"
  end

  def get(channel:)
    @db.transaction do
      @db[channel.id]
    end
  end

  def set(channel:, value:)
    @db.transaction do
      @db[channel.id] = value
    end
  end
end
