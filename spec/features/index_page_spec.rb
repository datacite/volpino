require 'rails_helper'

describe "index", type: :feature, js: true, vcr: true do
  it 'show index page' do
    visit '/'
    expect(page).to have_css ".panel-body", text: "Please register with DataCite Profiles for DataCite services that require authentication. You register by signing in via your ORCID account. The supported services are listed below, other services will be added over time."
  end

  it 'show link to services' do
    sign_in
    visit '/'
    expect(page).to have_css ".navbar-nav li a", text: "Services"
  end

  it 'not authorized' do
    visit '/'
    expect(page).not_to have_css ".navbar-nav li a", text: "Services"
  end

  it 'invalid_credentials' do
    OmniAuth.config.mock_auth[:default] = :invalid_credentials
    sign_in
    visit '/'
    expect(page).not_to have_css ".navbar-nav li a", text: "Services"
  end

  it 'role user' do
    OmniAuth.config.add_mock(:default, { info: { "role" => "user" }})
    sign_in(role: "user")
    visit '/'
    expect(page).not_to have_css ".navbar-nav li a", text: "Services"
  end
end
