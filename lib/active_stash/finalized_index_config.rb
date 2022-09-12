module ActiveStash
  class FinalizedIndexConfig
    attr_reader :indexes

    def initialize(indexes, callback_registration_handlers)
      @indexes = ActiveStash::IndexLookup.new(indexes)
      @callback_registration_handlers = callback_registration_handlers
    end

    def register_callbacks
      @callback_registration_handlers.each{|register| register.call()}
    end
  end
end
