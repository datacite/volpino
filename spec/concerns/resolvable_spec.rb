require 'rails_helper'

describe Claim, type: :model, vcr: true do

  subject { FactoryGirl.create(:claim) }

  context "HTTP" do
    let(:url) { "http://127.0.0.1/api/claims/#{subject.uuid}" }
    let(:data) { { "name" => "Fred" } }
    let(:post_data) { { "name" => "Jack" } }

    context "get_doi_ra" do
      it "doi crossref" do
        doi = "10.1371/journal.pone.0000030"
        expect(subject.get_doi_ra(doi)).to eq("crossref")
      end

      it "doi crossref escaped" do
        doi = "10.1371%2Fjournal.pone.0000030"
        expect(subject.get_doi_ra(doi)).to eq("crossref")
      end

      it "doi datacite" do
        doi = "10.5061/dryad.8515"
        expect(subject.get_doi_ra(doi)).to eq("datacite")
      end

      it "invalid DOI" do
        doi = "10.1371/xxx"
        expect(subject.get_doi_ra(doi)).to eq("errors"=>[{"title"=>"An error occured", "status"=>400}])
      end
    end

    context "metadata" do
      before(:each) { allow(Time.zone).to receive(:now).and_return(Time.mktime(2015, 6, 25)) }

      let(:doi) { "10.1371/journal.pone.0000030" }

      it "get_metadata crossref" do
        response = subject.get_metadata(doi, "crossref")
        expect(response["DOI"]).to eq(doi)
        expect(response["title"]).to eq("Triose Phosphate Isomerase Deficiency Is Caused by Altered Dimerization–Not Catalytic Inactivity–of the Mutant Enzymes")
        expect(response["container-title"]).to eq("PLoS ONE")
        expect(response["issued"]).to eq("date-parts"=>[[2006, 12, 20]])
        expect(response["type"]).to eq("article-journal")
      end

      it "get_metadata datacite" do
        doi = "10.6084/M9.FIGSHARE.156595"
        response = subject.get_metadata(doi, "datacite")
        expect(response["DOI"]).to eq(doi)
        expect(response["title"]).to eq("Uncovering Impact - Moving beyond the journal article and beyond the impact factor")
        expect(response["container-title"]).to eq("Figshare")
        expect(response["author"]).to eq([{"family"=>"Trends", "given"=>"Research"}, {"family"=>"Piwowar", "given"=>"Heather", "ORCID"=>"http://orcid.org/0000-0003-1613-5981"}])
        expect(response["published"]).to eq("2013")
        expect(response["issued"]).to eq("2013-02-13T14:46:00Z")
        expect(response["type"]).to eq("Audiovisual")
      end

      it "get_metadata orcid" do
        orcid = "0000-0002-0159-2197"
        response = subject.get_metadata(orcid, "orcid")
        expect(response["title"]).to eq("ORCID record for Jonathan A. Eisen")
        expect(response["container-title"]).to eq("ORCID Registry")
        expect(response["issued"]).to eq("date-parts"=>[[2015, 6, 25]])
        expect(response["type"]).to eq("entry")
        expect(response["URL"]).to eq("http://orcid.org/0000-0002-0159-2197")
      end
    end

    context "crossref metadata" do
      before(:each) { allow(Time.zone).to receive(:now).and_return(Time.mktime(2015, 6, 25)) }

      let(:doi) { "10.1371/journal.pone.0000030" }

      it "get_crossref_metadata" do
        response = subject.get_crossref_metadata(doi)
        expect(response["DOI"]).to eq(doi)
        expect(response["title"]).to eq("Triose Phosphate Isomerase Deficiency Is Caused by Altered Dimerization–Not Catalytic Inactivity–of the Mutant Enzymes")
        expect(response["container-title"]).to eq("PLoS ONE")
        expect(response["issued"]).to eq("date-parts"=>[[2006, 12, 20]])
        expect(response["type"]).to eq("article-journal")
      end

      it "get_crossref_metadata with old DOI" do
        doi = "10.1890/0012-9658(2006)87[2832:tiopma]2.0.co;2"
        response = subject.get_crossref_metadata(doi)
        expect(response["DOI"]).to eq(doi)
        expect(response["title"]).to eq("THE IMPACT OF PARASITE MANIPULATION AND PREDATOR FORAGING BEHAVIOR ON PREDATOR–PREY COMMUNITIES")
        expect(response["container-title"]).to eq("Ecology")
        expect(response["issued"]).to eq("date-parts"=>[[2006, 11]])
        expect(response["type"]).to eq("article-journal")
      end

      it "get_crossref_metadata with date in future" do
        doi = "10.1016/j.ejphar.2015.03.018"
        response = subject.get_crossref_metadata(doi)
        expect(response["DOI"]).to eq(doi)
        expect(response["title"]).to eq("Paving the path to HIV neurotherapy: Predicting SIV CNS disease")
        expect(response["container-title"]).to eq("European Journal of Pharmacology")
        expect(response["issued"]).to eq("date-parts"=>[[2016, 8, 20]])
        expect(response["type"]).to eq("article-journal")
      end

      it "get_crossref_metadata with not found error" do
        response = subject.get_crossref_metadata("#{doi}x")
        expect(response).to eq("errors"=>[{"status"=>404, "title"=>"Not found"}])
      end
    end

    context "datacite metadata" do
      before(:each) { allow(Time.zone).to receive(:now).and_return(Time.mktime(2015, 6, 25)) }

      let(:doi) { "10.5061/DRYAD.8515" }

      it "get_datacite_metadata" do
        response = subject.get_datacite_metadata(doi)
        expect(response["DOI"]).to eq(doi)
        expect(response["title"]).to eq("Data from: A new malaria agent in African hominids")
        expect(response["container-title"]).to eq("Dryad Digital Repository")
        expect(response["author"]).to eq([{"family"=>"Ollomo", "given"=>"Benjamin"}, {"family"=>"Durand", "given"=>"Patrick"}, {"family"=>"Prugnolle", "given"=>"Franck"}, {"family"=>"Douzery", "given"=>"Emmanuel J. P."}, {"family"=>"Arnathau", "given"=>"Céline"}, {"family"=>"Nkoghe", "given"=>"Dieudonné"}, {"family"=>"Leroy", "given"=>"Eric"}, {"family"=>"Renaud", "given"=>"François"}])
        expect(response["published"]).to eq("2011")
        expect(response["issued"]).to eq("2011-02-01T17:32:02Z")
        expect(response["type"]).to eq("Dataset")
      end

      it "get_datacite_metadata with not found error" do
        response = subject.get_datacite_metadata("#{doi}x")
        expect(response).to eq("errors"=>[{"title"=>"Not found.", "status"=>404}])
      end
    end

    context "orcid metadata" do
      before(:each) { allow(Time.zone).to receive(:now).and_return(Time.mktime(2015, 6, 25)) }

      let(:orcid) { "0000-0002-0159-2197" }

      it "get_orcid_metadata" do
        response = subject.get_orcid_metadata(orcid)
        expect(response["title"]).to eq("ORCID record for Jonathan A. Eisen")
        expect(response["container-title"]).to eq("ORCID Registry")
        expect(response["issued"]).to eq("date-parts"=>[[2015, 6, 25]])
        expect(response["type"]).to eq("entry")
        expect(response["URL"]).to eq("http://orcid.org/0000-0002-0159-2197")
      end

      it "get_orcid_metadata with not found error" do
        response = subject.get_orcid_metadata("#{orcid}x")
        expect(response).to eq("errors"=>[{"status"=>404, "title"=>"Not found"}])
      end
    end

    context "clean identifiers" do
      let(:url) { "http://journals.PLOS.org/plosone/article?id=10.1371%2Fjournal.pone.0000030&utm_source=FeedBurner#stuff" }
      let(:doi) { "10.5061/dryad.8515" }
      let(:id) { "http://doi.org/10.5061/dryad.8515" }

      it "get_normalized_url" do
        response = subject.get_normalized_url(url)
        expect(response).to eq("http://journals.plos.org/plosone/article?id=10.1371%2Fjournal.pone.0000030")
      end

      it "get_normalized_url invalid url" do
        url = "article?id=10.1371%2Fjournal.pone.0000030"
        response = subject.get_normalized_url(url)
        expect(response).to be_nil
      end

      it "doi_as_url" do
        response = subject.doi_as_url(doi)
        expect(response).to eq("http://doi.org/10.5061/dryad.8515")
      end

      it "get_doi_from_id" do
        response = subject.get_doi_from_id(id)
        expect(response).to eq("10.5061/dryad.8515")
      end

      it "get_doi_from_id https" do
        id = "https://doi.org/10.5061/dryad.8515"
        response = subject.get_doi_from_id(id)
        expect(response).to eq("10.5061/dryad.8515")
      end

      it "get_doi_from_id dx.doi.org" do
        id = "http://dx.doi.org/10.5061/dryad.8515"
        response = subject.get_doi_from_id(id)
        expect(response).to eq("10.5061/dryad.8515")
      end
    end
  end
end
