module ActiveStash
  # Implements the DSL for adding searcable encrypted indexes to ActiveRecord
  # models.
  #
  # String/text fields support exact and range indexes but cannot be both. There
  # is no point.
  #
  # A string field specified as using the :defaults, or with no options at all
  # will be assumed to be :range and :match.
  #
  # Although it's hard to justify :match as being a worthy default: for any
  # given field the text munging should be customized for it to be geniunely a
  # useful default.
  #
  #   stash_index do
  #       # A range, unique index
  #       email :range, :unique
  #
  #       # An exact, unique index
  #       email :exact, :unique
  #       email :auto, :unique
  #
  #       name :match
  #
  #       # Same as: name :auto
  #       name
  #       # Same as: name :range, :match
  #       name :auto
  #
  #       # Associations
  #       # Note that associations do not support unique indexes
  #       patients do
  #         name :auto
  #         email :auto
  #       end
  #   end
  #
  # The short form of the syntax:
  #
  #   stash_index [:email, :name]
  #   stash_index [:email, :name], :auto
  #   stash_index :email, :unique
  #
  # Same as:
  #
  #   stash_index do
  #       email :auto, :unique
  #       name :auto
  #   end
  #
  #   # This is better - refactor to this later
  #   stash_index do
  #       auto :email, :name
  #       range :dob
  #   end
  class IndexDSL < BasicObject
    attr_reader :indexes

    def initialize(model_class, reflector = nil)
      @model_class = model_class
      @reflector = reflector || Reflector.new(@model_class)
      @indexes = []
    end

    def method_missing(name, *args, **opts, &block)
      if @reflector.fields.include?(name.to_s)
        field_type = @reflector.fields[name.to_s]
        requested_index_type = validate_index_type(args[0])
        is_unique = validate_unique_option(args[1])
        candidate_index_types = select_index_types(field_type, requested_index_type, is_unique)
        candidate_index_types.each do |(index_type, unique)|
          @indexes.push(Index.send(index_type, name.to_s, unique: unique))
        end
      elsif @reflector.associations.include?(name.to_s)
        ::Kernel.raise ConfigError, "Indexing of associations is not yet supported"
      else
        ::Kernel.raise ConfigError, "Unknown field or association '#{name}' on model #{@model_class}"
      end
    end

    private

    def validate_unique_option(unique)
      if !unique.present?
        false
      elsif unique == :unique
        true
      else
        raise ConfigError, "Unknown option '#{unique}'"
      end
    end

    def select_index_types(field_type, index_type, unique)
      selection = Index::FIELD_TYPE_TO_SUPPORTED_INDEX_TYPES[field_type].select do |t|
        index_type == :auto || t == index_type
      end

      if selection.size == 0
        ::Kernel.raise ConfigError, "An index of type '#{index_type}' cannot index fields of type '#{field_type}'"
      end

      selection.map do |t|
        if !unique
          [t, false]
        else
          if index_type == :match && unique
            ::Kernel::raise ::ActiveStash::ConfigError, "A match index cannot have a unique constraint"
          end

          [t, (field_type == :string || field_type == :text) && t == :exact]
        end
      end
    end

    def validate_index_type(index_type)
      if VALID_INDEX_TYPES.include?(index_type)
        index_type
      else
        ::Kernel.raise ConfigError, "Unknown index type '#{index_type}'. Valid index types are #{VALID_INDEX_TYPES.join(", ")}"
      end
    end

    VALID_INDEX_TYPES = [:exact, :range, :match, :auto]
  end

  class Reflector
    def initialize(model_class)
      @model_class = model_class
    end

    def fields
      @fields ||= ::ActiveStash::ModelReflection.fields(@model_class)
    end

    def associations
      @associations ||= ::ActiveStash::ModelReflection.associations(@model_class)
    end
  end
end