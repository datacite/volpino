# frozen_string_literal: true

require "rails_helper"

describe "OmniauthCallbacks", type: :controller do
  subject { Users::OmniauthCallbacksController.new }

  it "proper encoding" do
    jwt = "abc"
    cookie = subject.encode_cookie(jwt)
    expect(cookie[:value]).to start_with("{\"authenticated\":{\"authenticator\":\"authenticator:oauth2\"")
    expect(cookie[:domain]).to eq("localhost")
  end
end
