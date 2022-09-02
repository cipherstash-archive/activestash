module ActiveStash
  module ModelReflection

    def self.fields(model)
      fields = model.attribute_types.inject({}) do |attrs, (k,v)|
        type = v.type

        # ActiveRecord encryption is available from Rails 7.
        if Rails::VERSION::MAJOR >= 7
          type = ActiveRecord::Encryption::EncryptedAttributeType === v ? v.cast_type.type : v.type
        end

        attrs[k] = type
        attrs
      end

      without_lockbox_fields(fields, model)
      without_id_fields(fields)

      fields
    end

    private

    def self.without_lockbox_fields(fields, model)
      if model.respond_to?(:lockbox_attributes)
        model.lockbox_attributes.each do |(attr, settings)|
          if settings[:attribute] != settings[:encrypted_attribute]
            fields.delete(settings[:encrypted_attribute])
          end
        end
      end
    end

    def self.without_id_fields(fields)
      fields.delete("id")
      fields.delete("stash_id")
    end
  end
end