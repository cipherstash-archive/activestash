require "active_stash/schema_builder"

module ActiveStash::Generators
  class SchemaGenerator < Rails::Generators::NamedBase
    desc "Generates a schema file for a stash collection for the given model"
    def create_schema
      json = ActiveStash::SchemaBuilder.new(get_model).build
      create_file "db/stash/#{collection_name}.json", JSON.pretty_generate(json)
    end

    private
      def get_model
        # TODO: Check that this is an ActiveRecord
        @get_model ||= class_name.constantize.tap do |model|
          if !model.respond_to?(:is_stash_model?) || !model.is_stash_model?
            raise <<-STR
            '#{class_name}' is not stash enabled!
            
            You probably want to `include ActiveStash::Search` in `#{class_name}`
            STR
          end
        end
      rescue NameError
        raise "No class found called #{class_name}"
      end

      def collection_name
        get_model.collection_name
      end
  end
end

