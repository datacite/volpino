# frozen_string_literal: true

require "rails_helper"
require "cancan/matchers"

describe User, type: :model, vcr: true, elasticsearch: true do
  subject { FactoryBot.create(:valid_user, github: "mfenner", github_put_code: nil) }

  it { is_expected.to validate_uniqueness_of(:uid).case_insensitive }
  it { is_expected.to have_many(:claims) }
  it { is_expected.to strip_attribute(:given_names).collapse_spaces }
  it { is_expected.to strip_attribute(:family_name).collapse_spaces }
  it { is_expected.to strip_attribute(:name).collapse_spaces }


  describe "attribute normalization" do
    it "converts empty strings to nil" do
      user = User.new(name: "  ", given_names: "", family_name: "   ")
      user.valid?
      expect(user.name).to be_nil
      expect(user.given_names).to be_nil
      expect(user.family_name).to be_nil
    end

    it "preserves non-empty values" do
      user = User.new(name: "  John Doe  ", given_names: "  John  ")
      user.valid?
      expect(user.name).to eq("John Doe")
      expect(user.given_names).to eq("John")
    end
  end

  describe "jwt" do
    subject { FactoryBot.create(:regular_user) }

    it "is user" do
      payload = subject.decode_token(subject.jwt)
      expect(payload["uid"]).to eq(subject.uid)
      expect(payload["role_id"]).to eq("user")
    end

    it "is admin" do
      subject = FactoryBot.create(:admin_user)
      payload = subject.decode_token(subject.jwt)
      expect(payload["uid"]).to eq(subject.uid)
      expect(payload["role_id"]).to eq("staff_admin")
      expect(payload["features"]).to eq("delete-doi" => false)
    end
  end

  describe "process_data", order: :defined do
    let(:put_code) { 5582 }

    it "delete claim" do
      subject = FactoryBot.create(:valid_user, github: "mfenner", github_put_code: put_code)
      expect(subject.process_data).to_not(eq(nil))
      expect(subject.github_put_code).to eq(put_code)
    end
  end

  describe "claims from ORCID" do
    subject { FactoryBot.create(:valid_user) }

    it "get data" do
      result = subject.get_data
      expect(result.length).to eq(23)
      work = result.first
      path = work.fetch("work-summary", [{}]).first.fetch("source", {}).fetch("source-client-id", {}).fetch("path", nil)
      expect(path).to eq(ENV["ORCID_AUTO_UPDATE_CLIENT_ID"])
    end

    it "parse data" do
      result = subject.get_data

      result = subject.parse_data(result)
      expect(result.length).to eq(23)
      expect(result.first).to eq("10.5256/f1000research.67475.r16884")
    end
  end

  describe "claims from failed" do
    subject { FactoryBot.create(:valid_user) }

    let!(:claim) { FactoryBot.create(:claim, user: subject, orcid: "0000-0001-6528-2027", doi: "10.6084/M9.FIGSHARE.1041821", state: "failed") }

    it "queue_claims_jobs" do
      subject.queue_claim_jobs
      expect(subject.claims.count).to eq(1)
      updated_claim = subject.claims.first
      expect(updated_claim.state).to eq("failed")
    end
  end

  describe "uid containing lowercase x" do
    subject { FactoryBot.create(:valid_user, uid: "0000-0002-1111-827x") }

    let!(:claim) { FactoryBot.create(:claim, user: subject, orcid: "0000-0002-1111-827x", doi: "10.6084/M9.FIGSHARE.1041821", state: "failed") }

    it "creates Claim work and notification attributes with capital X for ORCID API" do
      expect(claim.work.orcid).to eq("0000-0002-1111-827X")
      expect(claim.notification.orcid).to eq("0000-0002-1111-827X")
      expect(subject.claims.first.doi).to eq("10.6084/M9.FIGSHARE.1041821")
    end
  end
end
