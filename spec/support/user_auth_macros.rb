module UserAuthMacros
  def sign_in(role = "admin")
    FactoryGirl.create(:user, role: role)
    visit "/"
    click_link_or_button "Sign in with ORCID"
  end

  def sign_out
    visit "/sign_out"
  end
end

RSpec.configure do |config|
  config.include UserAuthMacros, type: :feature
end
