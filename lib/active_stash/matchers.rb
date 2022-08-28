require_relative "./assess"

if defined?(RSpec)
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
      assessment = ActiveStash::Assess.new.read_report(assessment_path)
      assessment_entry = assessment.fetch(model.name, [])
        .map { |field| field[:field].to_sym }
        # TODO: Need to check that encrypted attrs method exists
        .reject { |name| model.encrypted_attributes.include?(name) }
    end
  end
end
