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
      @indexes.select{|idx| idx.field.to_s == field.to_s}
    end

    def count_on(field)
      on(field).count
    end

    def on_and_of_type(field, index_type)
      @indexes.select{|idx| idx.field.to_s == field.to_s}.select{|idx| idx.type == index_type }
    end

    def has?(field, index_type)
      on(field).any?{|idx| idx.type == index_type }
    end
  end
end