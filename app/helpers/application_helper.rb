module ApplicationHelper
  def login_link
    link_to "Sign in with ORCID", user_omniauth_authorize_path(:orcid), :id => "sign-in", class: 'btn btn-default'
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

  def email_text
    if current_user.has_email?
      'success'
    elsif current_user.has_unconfirmed_email?
      'info'
    else
      'warning'
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

  def subscribed_text
    if current_user.has_email?
      '<span class="small pull-right">subscribed</span>'
    elsif current_user.has_unconfirmed_email?
      '<span class="small pull-right">pending</span>'
    else
      '<span class="small pull-right">not subscribed</span>'
    end
  end

  def roles
    %w(user data_centre member staff admin)
  end

  def member_types
    %w(full affiliate)
  end

  def regions
    { "AMER" => "Americas",
      "APAC" => "Asia and Pacific",
      "EMEA" => "EMEA" }
  end

  def settings
    Settings[ENV['MODE']]
  end

  def worker_label(status)
    case status
    when "working" then "panel-success"
    when "waiting" then "panel-default"
    else "panel-warning"
    end
  end

  def data_tags_for_api
    data = { per_page: 15, model: controller.controller_name, host: ENV['LAGOTTO_URL'] }
    data[:api_key] = current_user.api_key if current_user
    data[:page] = @page if @page.present?
    data[:source_id] = @source.name if @source.present?
    data[:contributor_id] = current_user.orcid if current_user.present?
    data[:sort] = @sort.name if @sort.present?

    { class: "navbar-text", id: "api_key", data: data }
  end
end
