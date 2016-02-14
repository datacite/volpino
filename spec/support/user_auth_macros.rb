module UserAuthMacros
  def sign_in(role = "admin")
    OmniAuth.config.add_mock(:orcid, { extra: { raw_info: { role: role }}})
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
