module ActiveStash
  class StashIndexes
    def initialize(model, config)
      @model = model

      build!(config || {})
    end

    # Returns the match_multi index if one is defined
    def get_match_multi
      @match_multi
    end

    def on(field)
      @field_indexes[field.to_s] || []
    end

    def all
      @indexes
    end

    def fields
      fields = @model.attribute_types.inject({}) do |attrs, (k,v)|
        type = v.type

        # ActiveRecord encryption is available from Rails 7.
        if Rails::VERSION::MAJOR >= 7
          type = ActiveRecord::Encryption::EncryptedAttributeType === v ? v.cast_type.type : v.type
        end

        attrs.tap { |a| a[k] = type }
      end
      handle_encrypted_types(fields)
    end

    private

    def build!(config)
      _fields = fields()
      @indexes = []

      if Hash === config[:indexes]
        config[:indexes].each do |field, options|
          type = _fields[field.to_s]

          targets =
            case type
              when *Index::RANGE_TYPES
                target_indexes(:range, options)

              when :string, :text
                target_indexes(:exact, :match, :range, options)

              when :boolean, :uuid
                target_indexes(:exact, options)

              else
                ActiveStash::Logger.warn("ignoring field '#{field}' which has type #{type} as index type cannot be implied")
                []
            end

          targets = validate_unique_targets(targets, options, field)

          @indexes.concat(new_indexes(field, targets, options))
        end
      end

      # TODO: Test this case
      if config[:multi]
        opts = {}
        # Check that all multi fields are texty
        config[:multi].each do |field|
          if field.is_a?(Hash)
            opts = field
          else
            type = _fields[field.to_s]
            unless type == :string || type == :text
              raise ConfigError, "Cannot specify field '#{field}' in stash_match_all because it is neither a string nor text type"
            end
          end
        end

        @match_multi = Index.match_multi(config[:multi], **opts)

        @indexes << @match_multi
      end

      @field_indexes = @indexes.each_with_object({}) do |index,field_indexes|
        arr = (field_indexes[index.field.to_s] ||= [])
        arr.push(index)
      end

      if @indexes.size == 0
        ActiveStash::Logger.warn("Model #{@model.class} has no indexes defined")
      end
    end

    def handle_encrypted_types(fields)
      if @model.respond_to?(:lockbox_attributes)
        @model.lockbox_attributes.each do |(attr, settings)|
          if settings[:attribute] != settings[:encrypted_attribute]
            fields.delete(settings[:encrypted_attribute])
          end
        end
      end

      ignore_ids(fields)
    end

    def ignore_ids(fields)
      fields.tap do |f|
        f.delete("id")
        f.delete("stash_id")
      end
    end

    def unique_constraint_on_match_index?(options, targets)
      (options.key?(:unique) && targets.member?(:match)) && (!targets.member?(:exact) && !targets.member?(:range))
    end

    # Returns original targets as is if a unique key has not been specified on the field.
    #
    # It will raise a config error if a unique key has been provided and only a match index has been set on the field.
    #
    # Otherwise will map through the targets and update only the exact and range indexes as
    # unique indexes and return other targets as is.
    def validate_unique_targets(targets, options, field)
      unique_constraint_on_match_index =
      if !options.key?(:unique)
        targets
      elsif unique_constraint_on_match_index?(options, targets)
        raise ConfigError, "Cannot specify field '#{field}' with a unique constraint on match"
      else
        targets.map do |t|
          case t
          when :exact
            options[:unique] ? :exact_unique : :exact
          when :range
            options[:unique] ? :range_unique : :range
          else
            t
          end
        end
      end
    end

    def target_indexes(*args)
      options = args.extract_options!
      if only = options[:only]
        args.select do |index_type|
          Array(only).include?(index_type)
        end
      elsif except = options[:except]
        args.reject do |index_type|
          Array(except).include?(index_type)
        end
      else
        args
      end
    end

    def new_indexes(field, index_types, index_options)
      if index_types.empty?
        ActiveStash::Logger.warn("configuration for '#{field}' means that it has no stash indexes defined")
      end

      Array(index_types).map do |index_type|
        case index_type
          when :exact; Index.exact(field)
          when :range; Index.range(field)
          when :match; Index.match(field, **index_options)
          when :exact_unique; Index.exact(field, unique: true)
          when :range_unique; Index.range(field, unique: true)
        end
      end
    end
  end
end
