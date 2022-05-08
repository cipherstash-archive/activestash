module ActiveStash
  class Reflection
    def initialize(collection)
      @collection = collection
    end

    def indexes
      @collection.instance_variable_get("@indexes")
    end

    def has_index?(target)
      indexes.any? do |index|
        mapping = index.instance_variable_get("@settings")["mapping"]
        meta = index.instance_variable_get("@settings")["meta"]
        # TODO: Check other fields, too
        target.name == meta["$indexName"]
      end
    end
  end
end
