require 'rails_helper'

describe "members", type: :feature, js: true, vcr: true do
  let!(:member) { FactoryGirl.create(:member) }

  it 'lists all members' do
    sign_in
    visit '/members'
    expect(page).to have_css ".panel-heading", text: member.title
  end

  it 'not authorized' do
    visit '/members'
    expect(page).to have_css "#flash_alert", text: "You are not authorized to access this page."
  end

  it 'invalid_credentials' do
    sign_in(credentials: "invalid")
    visit '/members'
    expect(page).to have_css "#flash_alert", text: "You are not authorized to access this page."
  end

  it 'role user' do
    sign_in(role: "user")
    visit '/members'
    expect(page).to have_css "#flash_alert", text: "You are not authorized to access this page."
  end
end
