module ActiveStash
  # Implements the DSL for adding searchable encrypted indexes to ActiveRecord
  # models that include ActiveStash::Search.
  #
  #   stash_index do
  #     auto :email, :first_name, :last_name
  #     unique :email
  #     range :created_at, :updated_at
  #     exact :gender
  #
  #     match :description, filter_term_bits: 512
  #
  #     match_all :first_name, :last_name, :email
  #
  #     index_assoc :patient do
  #       auto :email, :first_name, :last_name
  #     end
  #   end
  #
  class IndexDSL
    def initialize(model_class, path = [], reflector = nil)
      @model_class = model_class
      @reflector = reflector || Reflector.new(@model_class)
      @path = path || []
      @is_in_association = path.size > 0
      @indexes = []
      @associations = []
      @unique_fields = []
      @callback_registration_handlers = []
    end

    # Performs the following checks and operations before returning the final
    # indexes.
    #
    # 1. Validates that there are not multiple index definitions of the same
    # type for the same field.
    #
    # 2. Validates that there are not multiple associated indexes defined for
    # the same association.
    #
    # 3. Processes `unique` indexes by either:
    #
    #    - Updating existing `range` and `exact` indexes for a field to enforce
    #    uniqueness
    #
    #    - Creating an `exact` or `range` index for the field if one does not
    #    already exist (`string` and `text` fields generate `exact` indexes,
    #    everything else generates a `range` index).
    #
    def finalize!
      return @finalized_config if @finalized_config
      validate_no_fields_with_duplicate_index_definitions!
      validate_no_association_duplicates!
      process_unique_indexes!
      @finalized_config = ActiveStash::FinalizedIndexConfig.new(@indexes, @callback_registration_handlers)
    end


    # Automatically defines all applicable index types on one or more fields.
    def auto(*fields)
      fields.each do |name|
        if @reflector.fields.include?(name.to_s)
          field_type = @reflector.fields[name.to_s]
          Index.applicable_index_types(field_type).each do |index_type|
            @indexes.push(Index.send(index_type, name.to_s))
          end
        else
          raise ConfigError, "Attempted to auto index an unknown attribute '#{name}' on model '#{@model_class}'"
        end
      end
    end

    # Defines an exact index on one or more fields.
    def exact(*fields)
      fields.each do |name|
        if @reflector.fields.include?(name.to_s)
          field_type = @reflector.fields[name.to_s]
          if Index.valid_index_type_for_field_type?(:exact, field_type)
            @indexes.push(Index.exact(name.to_s))
          else
            raise ConfigError, "Attempted to create an exact index on type that does not support an exact index (attribute '#{name}' of model '#{@model_class})'"
          end
        else
          raise ConfigError, "Attempted to apply an exact index an unknown attribute '#{name}' on model '#{@model_class}'"
        end
      end
    end

    def range(*fields)
      fields.each do |name|
        if @reflector.fields.include?(name.to_s)
          field_type = @reflector.fields[name.to_s]
          if Index.valid_index_type_for_field_type?(:range, field_type)
            @indexes.push(Index.range(name))
          else
            raise ConfigError, "Attempted to create a range index on type that does not support an range index (attribute '#{name}' of model '#{@model_class})'"
          end
        else
          raise ConfigError, "Attempted to apply a range index an unknown attribute '#{name}' on model '#{@model_class}'"
        end
      end
    end

    def match(*fields, **opts)
      fields.each do |name|
        if @reflector.fields.include?(name.to_s)
          field_type = @reflector.fields[name.to_s]
          if Index.valid_index_type_for_field_type?(:match, field_type)
            @indexes.push(Index.match(name.to_s, **opts))
          else
            raise ConfigError, "Attempted to create a match index on type that does not support an range index (attribute '#{name}' of model '#{@model_class})'"
          end
        else
          raise ConfigError, "Attempted to apply a match index an unknown attribute '#{name}' on model '#{@model_class}'"
        end
      end
    end

    def match_all(*fields, **opts)
      raise ConfigError, "No fields specified for match_all" if fields.size == 0

      fields.each do |f|
        field_type = @reflector.fields[f.to_s]
        unless Index.valid_index_type_for_field_type?(:match, field_type)
          raise ConfigError, "Only attributes of type string or text can be used in a match_all index (attribute #{f} is of type #{field_type}) in model '#{@model_class}'"
        end
      end

      @indexes.push(Index.match_multi(fields, **opts))
    end

    # Defines a unique index on a single field.
    #
    # If no exact or range index already exists on the field, `unique` will
    # create a new exact index with a unique constraint.
    #
    # All existing exact and range indexes for the field will be modified to
    # enforce a unique constraint, except if the field is a `string` or `text`
    # type, in which case the unique constraint will only be applied to the
    # `exact` index. This is because `range` indexes on strings are lossy and
    # could cause false positive uniqueness checks.
    #
    def unique(field)
      if @is_in_association
        raise ConfigError, "Attempted to create a unique constraint on an associated model"
      end

      if @reflector.fields.include?(field.to_s)
        if @unique_fields.include?(field)
          raise ConfigError, "A unique constraint is already defined on '#{field}' on model '#{@model_class})"
        else
          @unique_fields.push(field)
        end
      else
        raise ConfigError, "Attempted to create a unique constraint on unknown attribute '#{field}' on model '#{@model_class})"
      end
    end

    # Pulls fields from an association into the index on this model. This is a
    # form of denormalisation.
    #
    # This mechanism works whether the foreign model includes
    # ActiveStash::Search or not.
    #
    # Currently, it is only possible to index `has_one` or `belongs_to`
    # associations.
    #
    def index_assoc(association, &block)
      unless ActiveStash::ModelReflection.association_names(@model_class).include?(association)
        raise ConfigError, "No such association '#{association}' on model '#{@model_class}'"
      end

      unless @path.size == 0
        raise ConfigError, "Nested association indexing is currently not supported"
      end

      associated_model = ActiveStash::ModelReflection.associated_model(@model_class, association)

      path = [*@path, association]
      dsl = IndexDSL.new(associated_model, @path, Reflector.new(associated_model))

      reflection = @model_class.reflect_on_association(association)

      unless [:has_one, :belongs_to].include?(reflection.macro)
        raise ConfigError, "Only 1-to-1 associations (belongs_to and has_one) are currently supported"
      end

      dsl.instance_eval(&block)
      association_indexes = dsl.finalize!.indexes
      @indexes.concat(association_indexes.indexes.map do |idx|
        idx.tap { |i| i.name = "#{path.join(".")}.#{i.name}" }
      end)


      inverse_name = reflection.inverse_of.name

      @callback_registration_handlers.push(-> {
        reflection.klass.after_save do |record|
          record.send(inverse_name).try(:cs_put)
        end

        reflection.klass.after_destroy do |record|
          # This will reindex every stash index associated with the model, not
          # only the index that needs updating.  We can get smarter about this
          # in the future.
          record.send(inverse_name).reload
          record.send(inverse_name).try(:cs_put)
        end
      })
    end

    private

    def validate_no_fields_with_duplicate_index_definitions!
      @indexes.group_by{|idx| idx.field }.each do |field, indexes|
        indexes.group_by{|idx| idx.type }.each do |index_type, indexes|
          if indexes.count > 1
            raise ConfigError, "Multiple indexes of the same type on the same attribute: #{@model_class}##{field}, index type: #{index_type}"
          end
        end
      end
    end

    def validate_no_association_duplicates!
      # TODO
    end

    # RULES:
    #
    # 1. If no exact or range index already exists on the field, `unique` will
    #    create a new exact index with a unique constraint.
    #
    # 2. Existing exact and range indexes for the field will be modified to
    #    enforce a unique constraint, subject to the following rules:
    #
    # 2a. If the field is of type text or string, the unique constraint will
    #     only be placed on the exact index.
    #
    # 2b. For every other field type, the unique constraint will be applied to
    #     both range and exact indexes.
    #
    def process_unique_indexes!
      lookup = ActiveStash::IndexLookup.new(@indexes.clone)

      @unique_fields.each do |uf|
        indexes_defined_on_field = lookup.on(uf.to_s).select{|idx| [:exact, :range].include?(idx.type) }
        if indexes_defined_on_field.size == 0
          # RULE 1.
          @indexes.push(Index.exact(uf.to_s, unique: true))
        else
          # RULE 2.
          field_type = @reflector.fields[uf.to_s]
          if [:string, :text].include?(field_type)
            # RULE 2a.
            exact_index = indexes_defined_on_field.find{|idx| idx.type == :exact }
            if exact_index
              exact_index.make_unique
            else
              @indexes.push(Index.exact(field, unique: true))
            end
          else
            # RULE 2b.
            indexes_defined_on_field.each do |idx|
              idx.make_unique
            end
          end
        end
      end
    end
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