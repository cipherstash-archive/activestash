module ActiveStash
  class Constraint
    attr_reader :type, :field, :value

    def initialize(type, field, value)
      @type = type
      @field = field
      @value = value
    end
  end

  class Query
    attr_reader :constraints 

    def initialize(&block)
      @constraints = []
      self.instance_eval(&block)
    end

    def method_missing(name, *args, &block)
      @field = name
      self
    end

    def eq(value)
      if @field
        @constraints << Constraint.new(:eq, @field, value)
        @field = nil
      end
      self
    end

    def >=(value)
      if @field
        @constraints << Constraint.new(:gte, @field, value)
        @field = nil
      end
      self
    end

    def and(query)
      puts "AND"
      @constraints << query
    end
  end

  class Stash
    def self.connect(collection_name)
      puts "Doing us a connect to #{collection_name}"
      sleep 0.5
      new(collection_name)
    end

    def initialize(name)
      @collection_name = name
    end

    def put(id, record)
      raise "Missing record" if record.nil?
      doc = Document.find_by(id: id)
      doc ||= Document.new(id: id)
      doc.body = record.attributes
      doc.save!
    end

    def delete(id)
      Document.find(id).destroy!
    end

    def query2(&block)
      #yield Query.new if block_given?
      Query.new(&block)
    end

    def query(field, constraint, value, order_by = nil)
      q =
      case constraint
      when "eq"
        Document.where(["body ->> '#{field}' = ?", value])
      end
      if order_by
        q = q.order(Arel.sql("body ->> '#{order_by}'"))
      end
      q.select(:id).map(&:id)
    end
  end
end
