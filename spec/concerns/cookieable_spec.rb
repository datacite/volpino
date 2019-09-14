require "rails_helper"

describe "OmniauthCallbacks", type: :controller do
  subject { Users::OmniauthCallbacksController.new }

  it "proper encoding" do
    jwt = "abc"
    cookie = subject.encode_cookie(jwt)
    expect(cookie[:expires].to_time.to_i - Time.now.to_i).to eq(2592000)
    expect(cookie[:value]).to start_with("{\"authenticated\":{\"authenticator\":\"authenticator:oauth2\"")
    expect(cookie[:domain]).to be_nil
  end
end
