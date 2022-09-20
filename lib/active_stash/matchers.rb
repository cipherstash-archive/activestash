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
      assessment = ActiveStash::Assess.new.read_report

      if assessment_outdated?(model, assessment)
        raise ActiveStash::AssessmentOutdated, <<~STR
          Assessment file is outdated.

          This probably means that the DB schema has changed since the assessment was generated.

          Try running `rake active_stash:assess` to update the assessment file.
        STR
      end

      assessment.fetch(model.name, [])
        .reject { |field| !field[:sensitive] }
        .map { |field| field[:field].to_sym }
        .reject { |field_name| encrypted?(model, field_name) }
    end

    def encrypted?(model, field_name)
      model.respond_to?(:encrypted_attributes) && model.encrypted_attributes.include?(field_name)
    end

    # Check if all fields in the model are in the report. We only care if the fields for the
    # model currently being tested are out of date.
    def assessment_outdated?(model, assessment)
      all_field_names = model.column_names.sort
      report_field_names = assessment
        .fetch(model.name, [])
        .map { |field| field[:field] }
        .sort

      report_field_names != all_field_names
    end
  end
end
