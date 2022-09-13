module ActiveStash
  module ModelReflection

    def self.fields(model_class)
      fields = model_class.attribute_types.inject({}) do |attrs, (k,v)|
        type = v.type

        # ActiveRecord encryption is available from Rails 7.
        if Rails::VERSION::MAJOR >= 7
          type = ActiveRecord::Encryption::EncryptedAttributeType === v ? v.cast_type.type : v.type
        end

        attrs[k] = type
        attrs
      end

      without_lockbox_fields(fields, model_class)
      without_id_fields(fields)

      fields
    end

    def self.associations(model)
      [:has_one, :belongs_to].map do |macro|
        model.reflect_on_all_associations(macro)
      end.flatten
    end

    def self.association_names(model)
      [:has_one, :belongs_to].map do |macro|
        model.reflect_on_all_associations(macro)
      end.flatten.map{|assoc| assoc.name }
    end

    def self.associated_model(parent_model, association)
      parent_model.reflect_on_association(association).klass
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