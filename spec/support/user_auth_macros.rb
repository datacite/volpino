module UserAuthMacros
  def sign_in(role = "admin", credentials = nil)
    if credentials == "invalid"
      OmniAuth.config.mock_auth[:orcid] = :invalid_credentials
    else
      OmniAuth.config.add_mock(:orcid, { extra: { raw_info: { role: role }}})
    end
    visit "/sign_in"
    click_link_or_button "Sign in with ORCID"
  end

  def sign_out
    visit "/sign_out"
  end
end

RSpec.configure do |config|
  config.include UserAuthMacros, type: :feature
end
