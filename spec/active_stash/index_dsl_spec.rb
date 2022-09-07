require 'spec_helper'

class FakeUserModel
end

class FakeReflector
  def fields
    { "first_name" => :string }
  end

  def associations
    {}
  end
end

RSpec.describe ActiveStash::IndexDSL do
  describe "invalid unique constraints" do
    it "should raise an error when trying to create a unique constraint on a match index" do
      expect do
        dsl = ActiveStash::IndexDSL.new(FakeUserModel, FakeReflector.new)
        dsl.instance_eval do
          first_name :match, :unique
        end
      end.to raise_error(ActiveStash::ConfigError)
    end
  end
end