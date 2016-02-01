module UserAuthMacros
  def sign_in(role = "admin")
    FactoryGirl.create(:user, uid: "0000-0002-1825-0097", role: role)
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
