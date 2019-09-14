require "rails_helper"

describe "OmniauthCallbacks", type: :controller do
  subject { Users::OmniauthCallbacksController.new }

  it "proper encoding" do
    jwt = "abc"
    cookie = subject.encode_cookie(jwt)
    expect(cookie[:expires].to_time.to_i - Time.now.to_i).to eq(2592000)
    expect(cookie[:value]).to start_with("%7B%22authenticated%22%3A%7B%22authenticator%22%3A%22authenticator%3Aoauth2%22%2C%22access_token%22%3A%22")
    expect(cookie[:domain]).to be_nil
  end
end
