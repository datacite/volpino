require 'rails_helper'

describe "services", type: :feature, js: true, vcr: true do
  let!(:service) { FactoryGirl.create(:service) }

  it 'lists all services' do
    sign_in
    visit '/services'
    expect(page).to have_css ".panel-heading", text: service.title
  end

  it 'not authorized' do
    visit '/services'
    expect(page).to have_css "#flash_alert", text: "You are not authorized to access this page."
  end

  it 'invalid_credentials' do
    sign_in(credentials: "invalid")
    visit '/services'
    expect(page).to have_css "#flash_alert", text: "You are not authorized to access this page."
  end

  it 'role user' do
    sign_in(role: "user")
    visit '/services'
    expect(page).to have_css "#flash_alert", text: "You are not authorized to access this page."
  end
end
