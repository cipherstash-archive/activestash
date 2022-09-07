module ActiveStash
  class IndexLookup
    attr_reader :indexes

    def initialize(indexes)
      @indexes = indexes
    end

    def concat(indexes)
      @indexes.concat(indexes)
    end

    def on(field)
      @indexes.select{|idx| idx.field == field.to_s}
    end
  end
end