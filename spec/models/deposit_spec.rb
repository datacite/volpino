require 'rails_helper'

describe Deposit, :type => :model, vcr: true do
  before(:each) { allow(Time.zone).to receive(:now).and_return(Time.mktime(2015, 4, 8)) }

  subject { FactoryGirl.create(:deposit) }

  it { is_expected.to validate_presence_of(:message) }

  describe "validate message" do
    it "format is a string" do
      subject = FactoryGirl.build(:deposit, message: "test")
      subject.valid?
      expect(subject.errors[:message]).to eq(["should be a hash"])
    end

    it "format is an array" do
      subject = FactoryGirl.build(:deposit, message: ["test"])
      subject.valid?
      expect(subject.errors[:message]).to eq(["should be a hash"])
    end

    it "does not contain required hash keys" do
      subject = FactoryGirl.build(:deposit, message: {})
      subject.valid?
      expect(subject.errors[:message]).to eq(["can't be blank", "should contain contributors"])
    end
  end

  describe "update_contributors" do
    # it "no related_work" do
    #   subject.update_contributors
    # end

    # it "crossref" do
    #   related_work = FactoryGirl.create(:work, doi: "10.1371/journal.pone.0043007")
    #   works = [{"author"=>[{"family"=>"Occelli", "given"=>"Valeria"}, {"family"=>"Spence", "given"=>"Charles"}, {"family"=>"Zampini", "given"=>"Massimiliano"}], "title"=>"Audiotactile Interactions In Temporal Perception", "container-title"=>"Psychonomic Bulletin & Review", "issued"=>{"date-parts"=>[[2011]]}, "DOI"=>"10.3758/s13423-011-0070-4", "volume"=>"18", "issue"=>"3", "page"=>"429", "type"=>"article-journal", "related_works"=>[{"related_work"=>"doi:10.1371/journal.pone.0043007", "source"=>"crossref", "relation_type"=>"cites"}]}]
    #   subject = FactoryGirl.create(:deposit, message_type: "crossref", message: { "works" => works })
    #   expect(subject.update_works).to eq(["http://doi.org/10.3758/s13423-011-0070-4"])

    #   expect(Work.count).to eq(2)
    #   work = Work.last
    #   expect(work.title).to eq("Audiotactile Interactions In Temporal Perception")
    #   expect(work.pid).to eq("http://doi.org/10.3758/s13423-011-0070-4")

    #   expect(work.relations.length).to eq(1)
    #   relation = Relation.first
    #   expect(relation.relation_type.name).to eq("cites")
    #   expect(relation.source.name).to eq("crossref")
    #   expect(relation.related_work).to eq(related_work)
    # end
  end
end
