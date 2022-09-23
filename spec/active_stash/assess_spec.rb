
require "active_stash/matchers"

RSpec.describe ActiveStash::Assess do
  describe "running an assessment and using the encrypt_sensitive_fields matcher" do
    it "succeeds when there are no models" do
      Dir.mktmpdir do |tmpdir|
        report_dir = Pathname.new(tmpdir)
        assess = described_class.new(models: [], report_dir: report_dir)

        expected_output = "Assessment written to: #{report_dir}\/active_stash_assessment.yml\n"

        expect { assess.run }.to output(expected_output).to_stdout

        expect(assess.read_report).to eq({})
      end
    end

    it "succeeds for a model with no encrypted fields" do
      Dir.mktmpdir do |tmpdir|
        report_dir = Pathname.new(tmpdir)
        assess = described_class.new(models: [AssessUserNoEncryption], report_dir: report_dir)

        expected_output = <<~STR
        AssessUserNoEncryption:
        - AssessUserNoEncryption.email is suspected to contain: emails (AS0001)

        Online documentation:
        - https://docs.cipherstash.com/assess/checks#AS0001

        Assessment written to: #{report_dir}\/active_stash_assessment.yml
        STR

        expected_report = {
          "AssessUserNoEncryption" => [
            {field: "id", sensitive: false},
            {comment: "suspected to contain: emails", field: "email", sensitive: true},
            {field: "created_at", sensitive: false},
            {field: "updated_at", sensitive: false},
          ]
        }

        expect { assess.run }.to output(expected_output).to_stdout

        expect(assess.read_report).to eq(expected_report)

        expect do
          expect(AssessUserNoEncryption).to encrypt_sensitive_fields(assess)
        end.to raise_error("Unprotected sensitive field: email")
      end
    end

    if Rails::VERSION::MAJOR >= 7
      it "succeeds for a model with active record encryption" do
        Dir.mktmpdir do |tmpdir|
          report_dir = Pathname.new(tmpdir)
          assess = described_class.new(models: [AssessUserActiveRecordEncryption], report_dir: report_dir)

          expected_output = <<~STR
          AssessUserActiveRecordEncryption:
          - AssessUserActiveRecordEncryption.email is suspected to contain: emails (AS0001)

          Online documentation:
          - https://docs.cipherstash.com/assess/checks#AS0001

          Assessment written to: #{report_dir}\/active_stash_assessment.yml
          STR

          expected_report = {
            "AssessUserActiveRecordEncryption" => [
              {field: "id", sensitive: false},
              {comment: "suspected to contain: emails", field: "email", sensitive: true},
              {field: "created_at", sensitive: false},
              {field: "updated_at", sensitive: false},
            ]
          }

          expect { assess.run }.to output(expected_output).to_stdout

          expect(assess.read_report).to eq(expected_report)

          expect(AssessUserActiveRecordEncryption).to encrypt_sensitive_fields(assess)
        end
      end
    end

    it "succeeds for a model with lockbox" do
      Dir.mktmpdir do |tmpdir|
        report_dir = Pathname.new(tmpdir)
        assess = described_class.new(models: [AssessUserLockbox], report_dir: report_dir)

        # Note that names aren't in the output here because the column is suffixed with _ciphertext
        expected_output = <<~STR
        AssessUserLockbox:
        - AssessUserLockbox.email is suspected to contain: emails (AS0001)

        Online documentation:
        - https://docs.cipherstash.com/assess/checks#AS0001

        Assessment written to: #{report_dir}\/active_stash_assessment.yml
        STR

        expected_report = {
          "AssessUserLockbox" => [
            {field: "id", sensitive: false},
            {comment: "suspected to contain: emails", field: "email", sensitive: true},
            # name is in the report, but it's not marked as sensitive because of the suffix
            {:field=>"name_ciphertext", :sensitive=>false},
            {field: "created_at", sensitive: false},
            {field: "updated_at", sensitive: false},
          ]
        }

        expect { assess.run }.to output(expected_output).to_stdout

        expect(assess.read_report).to eq(expected_report)

        expect(AssessUserLockbox).to encrypt_sensitive_fields(assess)
      end
    end
  end
end
