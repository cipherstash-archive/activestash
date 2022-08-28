RSpec::Matchers.define :be_indexed do |stash_id|
  match do |object|
    expect {
      object.class.collection.get(object.stash_id)
    }.to_not raise_error
  end
end

RSpec.describe "Indexing Callbacks" do
  before do
    User.collection.create!
    MedicareCard.collection.create!
  end

  after do
    User.collection.drop!
    MedicareCard.collection.drop!
  end

  describe "Saving a model" do
    it "indexes to a collection" do
      user = build(:user)
      user.save!

      expect(user).to be_indexed
    end

    it "indexes to a collection with a missing patient" do
      user = build(:user, patient: nil)
      user.save!

      expect(user).to be_indexed
      target = User.collection.get(user.stash_id)

      expect(target["first_name"]).to eq(user.first_name)
    end

    it "reindexes an already indexed model" do
      user = create(:user, stash_id: "8B195077-59D5-4189-8890-C14FE6A2FCBA")

      expect {
        user.first_name = "#{user.first_name}_1"
        user.save!
      }.to change {
        User.collection.get(user.stash_id)["first_name"]
      }
    end
  end

  # This tests that when saving an association of an indexed model
  # that has been specified using stash_index
  describe "Saving an indexed association" do
    it "indexes parent model to a collection" do
      user = create(:user)
      patient = user.patient
      patient.height = patient.height + 1
      patient.save!

      expect(user).to be_indexed
    end

    it "reindexes an already indexed parent" do
      user = create(:user, stash_id: "8B195077-59D5-4189-8890-C14FE6A2FCBA")
      patient = user.patient
      user.save!

      expect {
        patient.height = patient.height + 1
        patient.save!
      }.to change {
        User.collection.get(user.stash_id)["__patient_height"]
      }
    end

    it "skips indexing if the parent record is nil" do
      patient_without_user = create(:patient, user: nil)

      expect { patient_without_user.save! }.to_not raise_error
    end
  end

  describe "When both sides of an association are indexed but one does not index any associated values" do
    it "updates both indexes when the medicare_card is saved" do
      user = create(:user)
      medicare_card = user.medicare_card

      medicare_card.medicare_number = "XXXX"
      medicare_card.save!

      user_record = User.collection.get(user.stash_id)
      mc_record = MedicareCard.collection.get(medicare_card.stash_id)

      expect(user_record["__medicare_card_medicare_number"]).to eq("XXXX")
      expect(mc_record["medicare_number"]).to eq("XXXX")
    end
  end

  describe "Destruction of an indexed association" do
    it "reindexes the parent record" do
      user = create(:user)
      medicare_card = user.medicare_card

      medicare_card.medicare_number = "XXXX"
      medicare_card.save!

      user_record_before_deletion = User.collection.get(user.stash_id)
      expect(user_record_before_deletion["__medicare_card_medicare_number"]).to eq("XXXX")

      user.medicare_card.destroy

      user_record_after_deletion = User.collection.get(user.stash_id)
      expect(user_record_after_deletion["__medicare_card_medicare_number"]).to_not be_present
    end
  end
end
