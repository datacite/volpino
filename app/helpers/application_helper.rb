module ApplicationHelper
  def login_link
    case ENV['OMNIAUTH']
    when "github" then link_to "Sign in with Github", user_omniauth_authorize_path(:github), id: "sign_in"
    when "orcid" then link_to "Sign in with ORCID", user_omniauth_authorize_path(:orcid), id: "sign_in"
    when "persona" then
      form_tag "/users/auth/persona/callback", id: "persona_form", class: "navbar-form" do
        hidden_field_tag('assertion') +
        button_tag("Sign in with Persona", id: "sign_in_button", class: "btn btn-link persona")
      end.html_safe
    else
      link_to "Sign in not configured", "#", :id => "sign_in"
    end
  end

  def icon(icon, text = nil, html_options = {})
    text, html_options = nil, text if text.is_a?(Hash)

    content_class = "fa fa-#{icon}"
    content_class << " #{html_options[:class]}" if html_options.key?(:class)
    html_options[:class] = content_class

    html = content_tag(:i, nil, html_options)
    html << ' ' << text.to_s unless text.blank?
    html
  end

  def markdown(text)
    text = GitHub::Markdown.render_gfm(text)
    syntax_highlighter(text).html_safe
  end

  def syntax_highlighter(html)
    formatter = Rouge::Formatters::HTML.new(:css_class => 'hll')
    lexer = Rouge::Lexers::Shell.new

    doc = Nokogiri::HTML::DocumentFragment.parse(html)
    doc.search("//pre").each { |pre| pre.replace formatter.format(lexer.lex(pre.text)) }
    doc.to_s
  end

  def auto_update_text
    if !user_signed_in?
      'panel-default'
    elsif current_user.auto_update
      'panel-success'
    else
      'panel-warning'
    end
  end

  def enabled_text
    if !user_signed_in?
      ''
    elsif current_user.auto_update
      '<span class="small pull-right">enabled</span>'
    else
      '<span class="small pull-right">disabled</span>'
    end
  end

  def roles
    %w(user staff admin)
  end

  def settings
    Settings[ENV['MODE']]
  end
end
