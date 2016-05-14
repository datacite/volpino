require 'rails_helper'

describe "users", type: :feature, js: true, vcr: true do
  it 'lists all users' do
    sign_in
    visit '/users'
    expect(page).to have_css ".panel-heading", text: "a"
  end

  it 'not authorized' do
    visit '/users'
    expect(page).to have_css "#flash_alert", text: "You are not authorized to access this page."
  end

  it 'invalid_credentials' do
    sign_in(credentials: "invalid")
    visit '/users'
    expect(page).to have_css "#flash_alert", text: "You are not authorized to access this page."
  end

  it 'role user' do
    sign_in(role: "user")
    visit '/users'
    expect(page).to have_css "#flash_alert", text: "You are not authorized to access this page."
  end
end
