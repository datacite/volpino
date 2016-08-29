require 'rails_helper'

describe "index", type: :feature, js: true, vcr: true do
  it 'show index page' do
    visit '/'
    expect(page).to have_css ".motto p", text: "Please register for DataCite services that require authentication"
  end

  # it 'show link to admin' do
  #   sign_in
  #   visit '/'
  #   expect(page).to have_css ".navbar-nav li a", text: "Admin"
  # end

  it 'not authorized' do
    visit '/'
    expect(page).not_to have_css ".navbar-nav li a", text: "Admin"
  end

  it 'invalid_credentials' do
    sign_in(credentials: "invalid")
    visit '/'
    expect(page).not_to have_css ".navbar-nav li a", text: "Admin"
  end

  it 'role user' do
    sign_in(role: "user")
    visit '/'
    expect(page).not_to have_css ".navbar-nav li a", text: "Admin"
  end
end
