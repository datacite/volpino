require 'rails_helper'

describe User, type: :model, vcr: true do
  subject { FactoryGirl.create(:user, uid: '0000-0002-1825-0097') }

  describe 'access_token' do
    it 'should return the access_token' do
      expect(subject.access_token.token).not_to be_blank
    end
  end

  describe 'oauth_client_get' do
    it 'should get' do
      expect { subject.oauth_client_get }.to raise_error(OAuth2::Error)
    end
  end

  describe 'oauth_client_post' do
    it 'should post' do
      data = '<xml>'
      expect { subject.oauth_client_post(data) }.to raise_error(OAuth2::Error)
    end
  end
end
