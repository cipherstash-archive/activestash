if defined?(RSpec) && defined?(Rails)
  RSpec::Matchers.define :encrypt_sensitive_fields do
    match do |model|
      unprotected(model).empty?
    end

    failure_message do |model|
      unprotected = unprotected(model)

      field_text =
        if unprotected.size > 1
          "fields"
        else
          "field"
        end

      "Unprotected sensitive #{field_text}: #{unprotected.join(", ")}"
    end

    def unprotected(model)
      assessment = read_report(assessment_path)

      unprotected = []
      assessment.each do |model_name, fields|
        current_model = model_name.constantize
        if current_model == model
          suspected_fields = fields.map { |field| field[:field].to_sym }
          unencrypted = suspected_fields.reject { |name| model.encrypted_attributes.include?(name) }
          if unencrypted.size > 0
            unprotected = unencrypted
          end
        end
      end
      unprotected
    end

    def assessment_path
      # TODO
      # This depends on rails... is there another way to get this path?
      # Would also be nice to be able to configure this.
      Rails.root.join("active_stash_assessment.yml")
    end

    def read_report(filename)
      # TODO: catch error here and print nice error message if report is missing.
      # Should tell user to generate the report first.
      YAML.load(assessment_path.read)
    end
  end
end
