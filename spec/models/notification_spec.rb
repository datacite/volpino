require "rails_helper"

describe Notification, type: :model, vcr: true do
  let(:doi) { "10.6084/M9.FIGSHARE.1066168"}
  let(:user) { FactoryBot.create(:valid_user) }
  let(:notification_access_token) { ENV['NOTIFICATION_ACCESS_TOKEN'] }
  let(:put_code) { "292016" }

  subject { Notification.new(doi: doi, orcid: user.uid, notification_access_token: notification_access_token, put_code: put_code) }

  describe 'push to ORCID', :order => :defined do
    # describe 'post' do
    #   subject { Notification.new(doi: doi, orcid: user.uid, notification_access_token: notification_access_token) }
    
    #   it 'should create notification' do
    #     response = subject.create_notification(sandbox: true)
    #     expect(response.body["put_code"]).not_to be_blank
    #     expect(response.status).to eq(201)
    #   end
    # end

    # describe 'get' do
    #   it 'should get notification' do
    #     response = subject.get_notification(sandbox: true)
    #     notification = response.body.fetch("data", {}).fetch("notification", {})
    #     expect(notification["put_code"]).to eq("292016")
    #     expect(notification["items"]["item"]).to eq("item_type"=>"work", "item_name"=>"1000 random PLOS ONE DOIs from 2013", "external_id"=>nil)
    #     expect(response.status).to eq(200)
    #   end
    # end

    # describe 'delete' do
    #   it 'should delete notification' do
    #     response = subject.delete_notification(sandbox: true)
    #     notification = response.body.fetch("data", {}).fetch("notification", {})
    #     expect(notification["put_code"]).to eq("292016")
    #     expect(notification["items"]["item"]).to eq("item_type"=>"work", "item_name"=>"1000 random PLOS ONE DOIs from 2013", "external_identifier"=>nil)
    #     expect(response.status).to eq(200)
    #   end
    # end
  end

  describe 'schema' do
    it 'exists' do
      expect(subject.schema.errors).to be_empty
    end

    # it 'validates data' do
    #   expect(subject.validation_errors).to be_empty
    # end
    #
    # it 'validates item type work' do
    #   expect(subject.item_type).to eq("work")
    #   expect(subject.validation_errors).to be_empty
    # end

    it 'validates data with errors' do
      allow(subject).to receive(:metadata) { OpenStruct.new }
      expect(subject.validation_errors).to eq(["-1:0: ERROR: The document has no document element."])
    end
  end

  # it 'data' do
  #   doc = Nokogiri::XML(subject.data)
  #   expect(doc.at_xpath('//notification:item-name').children.first.text).to eq("1000 random PLOS ONE DOIs from 2013")
  # end
end
