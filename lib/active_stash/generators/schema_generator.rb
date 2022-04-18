require "active_stash/schema_builder"

module ActiveStash::Generators
  class SchemaGenerator < Rails::Generators::NamedBase
    desc "Generates a schema file for a stash collection for the given model"
    def create_schema
      json = ActiveStash::SchemaBuilder.new(get_model).build
      create_file "db/stash/#{singular_name}.json", JSON.pretty_generate(json)
    end

    private
      def get_model
        # TODO: Check that this is an ActiveRecord
        class_name.constantize
      rescue NameError
        raise "No class found called #{class_name}"
      end
  end
end

