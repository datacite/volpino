require 'rails_helper'

describe Claim, type: :model, vcr: true do

  subject { FactoryGirl.create(:claim) }

  context "HTTP" do
    let(:url) { "http://127.0.0.1/api/claims/#{subject.uuid}" }
    let(:data) { { "name" => "Fred" } }
    let(:post_data) { { "name" => "Jack" } }

    context "response" do
      it "get json" do
        stub = stub_request(:get, url).to_return(:body => data.to_json, :status => 200, :headers => { "Content-Type" => "application/json" })
        response = subject.get_result(url)
        expect(response).to eq(data)
        expect(stub).to have_been_requested
      end

      it "get xml" do
        stub = stub_request(:get, url).to_return(:body => data.to_xml, :status => 200, :headers => { "Content-Type" => "application/xml" })
        response = subject.get_result(url, content_type: 'xml')
        expect(response).to eq('hash' => data)
        expect(stub).to have_been_requested
      end

      it "get html" do
        stub = stub_request(:get, url).to_return(:body => data.to_s, :status => 200, :headers => { "Content-Type" => "text/html" })
        response = subject.get_result(url, content_type: 'html')
        expect(response).to eq(data.to_s)
        expect(stub).to have_been_requested
      end

      it "post xml" do
        stub = stub_request(:post, url).with(:body => post_data.to_xml).to_return(:body => data.to_xml, :status => 200, :headers => { "Content-Type" => "text/html" })
        subject.get_result(url, content_type: 'xml', data: post_data.to_xml) { |response| expect(Hash.from_xml(response.to_s)["hash"]).to eq(data) }
        expect(stub).to have_been_requested
      end
    end

    context "empty response" do
      it "get json" do
        stub = stub_request(:get, url).to_return(:body => nil, :status => 200, :headers => { "Content-Type" => "application/json" })
        response = subject.get_result(url)
        expect(response).to be_nil
        expect(stub).to have_been_requested
      end

      it "get xml" do
        stub = stub_request(:get, url).to_return(:body => nil, :status => 200, :headers => { "Content-Type" => "application/xml" })
        response = subject.get_result(url, content_type: 'xml')
        expect(response).to be_blank
        expect(stub).to have_been_requested
      end

      it "get html" do
        stub = stub_request(:get, url).to_return(:body => nil, :status => 200, :headers => { "Content-Type" => "text/html" })
        response = subject.get_result(url, content_type: 'html')
        expect(response).to be_blank
        expect(stub).to have_been_requested
      end

      it "post xml" do
        stub = stub_request(:post, url).with(:body => post_data.to_xml).to_return(:body => nil, :status => 200, :headers => { "Content-Type" => "application/xml" })
        subject.get_result(url, content_type: 'xml', data: post_data.to_xml) { |response| expect(response).to be_nil }
        expect(stub).to have_been_requested
      end
    end

    context "not found" do
      let(:error) { { "error" => "Not Found"} }

      it "get json" do
        stub = stub_request(:get, url).to_return(:body => error.to_json, :status => [404], :headers => { "Content-Type" => "application/json" })
        expect(subject.get_result(url)).to eq(error: error['error'], status: 404)
        expect(stub).to have_been_requested
      end

      it "get xml" do
        stub = stub_request(:get, url).to_return(:body => error.to_xml, :status => [404], :headers => { "Content-Type" => "application/xml" })
        expect(subject.get_result(url, content_type: 'xml')).to eq(error: { 'hash' => error }, status: 404)
        expect(stub).to have_been_requested
      end

      it "get html" do
        stub = stub_request(:get, url).to_return(:body => error.to_s, :status => [404], :headers => { "Content-Type" => "text/html" })
        expect(subject.get_result(url, content_type: 'html')).to eq(error: error.to_s, status: 404)
        expect(stub).to have_been_requested
      end

      it "post xml" do
        stub = stub_request(:post, url).with(:body => post_data.to_xml).to_return(:body => error.to_xml, :status => [404], :headers => { "Content-Type" => "application/xml" })
        subject.get_result(url, content_type: 'xml', data: post_data.to_xml) { |response| expect(Hash.from_xml(response.to_s)["hash"]).to eq(error) }
        expect(stub).to have_been_requested
      end
    end

    context "request timeout" do
      it "get json" do
        stub = stub_request(:get, url).to_return(:status => [408])
        response = subject.get_result(url)
        expect(response).to eq(error: "the server responded with status 408 for #{url}", status: 408)
        expect(stub).to have_been_requested
      end

      it "get xml" do
        stub = stub_request(:get, url).to_return(:status => [408])
        response = subject.get_result(url, content_type: 'xml')
        expect(response).to eq(error: "the server responded with status 408 for #{url}", status: 408)
        expect(stub).to have_been_requested
      end

      it "get html" do
        stub = stub_request(:get, url).to_return(:status => [408])
        response = subject.get_result(url, content_type: 'html')
        expect(response).to eq(error: "the server responded with status 408 for #{url}", status: 408)
        expect(stub).to have_been_requested
      end

      it "post xml" do
        stub = stub_request(:post, url).with(:body => post_data.to_xml).to_return(:status => [408])
        subject.get_result(url, content_type: 'xml', data: post_data.to_xml) { |response| expect(response).to be_nil }
        expect(stub).to have_been_requested
      end
    end

    context "request timeout internal" do
      it "get json" do
        stub = stub_request(:get, url).to_timeout
        response = subject.get_result(url)
        expect(response).to eq(error: "execution expired for #{url}", status: 408)
        expect(stub).to have_been_requested
      end

      it "get xml" do
        stub = stub_request(:get, url).to_timeout
        response = subject.get_result(url, content_type: 'xml')
        expect(response).to eq(error: "execution expired for #{url}", status: 408)
        expect(stub).to have_been_requested
      end

      it "get html" do
        stub = stub_request(:get, url).to_timeout
        response = subject.get_result(url, content_type: 'html')
        expect(response).to eq(error: "execution expired for #{url}", status: 408)
        expect(stub).to have_been_requested
      end

      it "post xml" do
        stub = stub_request(:post, url).with(:body => post_data.to_xml).to_timeout
        subject.get_result(url, content_type: 'xml', data: post_data.to_xml) { |response| expect(response).to be_nil }
        expect(stub).to have_been_requested
      end
    end

    context "too many requests" do
      it "get json" do
        stub = stub_request(:get, url).to_return(:status => [429])
        response = subject.get_result(url)
        expect(response).to eq(error: "the server responded with status 429 for #{url}. Rate-limit  exceeded.", status: 429)
        expect(stub).to have_been_requested
      end

      it "get xml" do
        stub = stub_request(:get, url).to_return(:status => [429])
        response = subject.get_result(url, content_type: 'xml')
        expect(response).to eq(error: "the server responded with status 429 for #{url}. Rate-limit  exceeded.", status: 429)
        expect(stub).to have_been_requested
      end

      it "get html" do
        stub = stub_request(:get, url).to_return(:status => [429])
        response = subject.get_result(url, content_type: 'html')
        expect(response).to eq(error: "the server responded with status 429 for #{url}. Rate-limit  exceeded.", status: 429)
        expect(stub).to have_been_requested
      end

      it "post xml" do
        stub = stub_request(:post, url).with(:body => post_data.to_xml).to_return(:status => [429])
        subject.get_result(url, content_type: 'xml', data: post_data.to_xml) { |response| expect(response).to be_nil }
        expect(stub).to have_been_requested
      end
    end
  end
end
