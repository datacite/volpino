require 'rails_helper'

describe "claims", type: :feature, js: true do
  it 'users' do
    visit '/status'
    expect(page).to have_css ".panel"
    expect(page).to have_css ".panel-heading", text: "Users"
  end

  it 'search and link' do
    visit '/status'
    expect(page).to have_css ".panel"
    expect(page).to have_css ".panel-heading", text: "Claims Search and Link"
  end

  it 'auto-update' do
    visit '/status'
    expect(page).to have_css ".panel"
    expect(page).to have_css ".panel-heading", text: "Claims Auto-Update"
  end

  it 'jobs for admin' do
    sign_in
    visit '/status'
    expect(page).to have_css ".panel-heading", text: "Jobs"
  end

  it 'database for admin' do
    sign_in
    visit '/status'
    expect(page).to have_css ".panel-heading", text: "Database size"
  end
end
