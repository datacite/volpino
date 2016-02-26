require 'rails_helper'

describe "tags", type: :feature, js: true, vcr: true do
  let!(:tag) { FactoryGirl.create(:tag) }

  it 'lists all tags' do
    sign_in
    visit '/tags'
    expect(page).to have_css ".panel-heading", text: tag.title
  end

  it 'not authorized' do
    visit '/tags'
    expect(page).to have_css "#flash_alert", text: "You are not authorized to access this page."
  end

  it 'invalid_credentials' do
    sign_in(credentials: "invalid")
    visit '/tags'
    expect(page).to have_css "#flash_alert", text: "You are not authorized to access this page."
  end

  it 'role user' do
    sign_in(role: "user")
    visit '/tags'
    expect(page).to have_css "#flash_alert", text: "You are not authorized to access this page."
  end
end
