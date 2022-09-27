require_relative "./assess/column_name_rules"
require_relative "./error"

module ActiveStash
  # Class for generating, writing, and reading Assess reports.
  #
  # Currently only supports Rails applications.
  #
  # @private
  class Assess
    REPORT_FILE_NAME = "active_stash_assessment.yml"
    DOCS_BASE_URL = "https://docs.cipherstash.com/assess/checks"

    def initialize(quiet: false, models: default_models, report_dir: Rails.root)
      @assessment_path = report_dir.join(REPORT_FILE_NAME)
      @models = models
      @quiet = quiet
    end

    def default_models
      if defined?(ApplicationRecord)
        ApplicationRecord.descendants
      else
        []
      end
    end

    # Run an assessment and generate a report. Results are printed to stdout and written to active_stash_assessment.yml.
    def run
      assessment = @models.map { |model| [model.name, suspected_personal_data(model)] }

      write_report(assessment, @assessment_path)

      unless @quiet
        print_results(assessment)
        puts "Assessment written to: #{@assessment_path}"
      end
    end

    # Read the report from active_stash_assessment.yml.
    #
    # @return [Hash] the report results.
    #
    # @raise [ActiveStash::AssessmentNotFound] if the report does not exist.
    def read_report
      begin
        YAML.load(@assessment_path.read)
      rescue Errno::ENOENT
        raise AssessmentNotFound, <<~STR
          Assessment not found at #{@assessment_path}.

          This probably means that the assessment hasn't been generated.

          Try running `rake active_stash:assess` first.
        STR
      end
    end

    def report_exists?
      File.exist?(@assessment_path)
    end

    private

    def print_results(assessment)
      assessment.each do |model, fields|
        if fields.size > 0
          puts "#{model}:"
          fields.each do |field, evidences|
            if evidences.size > 0
              puts "- #{model}.#{field} is suspected to contain: #{evidences.map { |e| e[:display_name] }.join(", ")} (#{evidences.map{ |e| e[:error_code] }.uniq.join(", ")})"
            end
          end
          puts
        end
      end

      error_codes = assessment.map { |model, fields| fields.values }
        .flatten
        .map {|e| e[:error_code] }
        .uniq

      if error_codes.length > 0
        puts "Online documentation:"
        puts "#{error_codes.map{ |e| "- #{DOCS_BASE_URL}##{e}"}.join("\n")}"
        puts
      end
    end

    def model_fields(model)
      model.column_names
    end

    def secured_by_active_stash?(fields)
      fields.include?("stash_id")
    end

    def suspected_personal_data(model)
      fields = model_fields(model)
      ColumnNameRules.check(fields)
    end

    def write_report(assessment, filename)
      report = {}
      assessment.each do |model, fields|
        fields.each do |field, reasons|
          report[model] ||= []

          if reasons.size > 0
            display = reasons.map { |r| r[:display_name] }.join(", ")
            report[model] << { field: field, sensitive: true, comment: "suspected to contain: #{display}" }
          else
            report[model] << { field: field, sensitive: false }
          end
        end
      end

      File.open(filename, "w") { |file| file.write(report.to_yaml) }
    end
  end
end
