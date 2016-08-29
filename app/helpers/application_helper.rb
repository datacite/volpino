module ApplicationHelper
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
    else
      'warning'
    end
  end

  def claim_text
    if current_user.claims.failed.count > 0
      'panel-warning'
    elsif current_user.claims.done.count > 0
      'panel-success'
    elsif current_user.claims.stale.count > 0
      'panel-info'
    else
      'panel-default'
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
    else
      '<span class="small pull-right">not subscribed</span>'
    end
  end

  def roles
    %w(user data_centre data_centre_admin member_representative member_technical_contact member_billing_contact staff admin)
  end

  def member_types
    %w(allocating non-allocating)
  end

  def regions
    { "AMER" => "Americas",
      "APAC" => "Asia Pacific",
      "EMEA" => "EMEA" }
  end

  def sources
    { "orcid_search" => "ORCID Search and Link",
      "orcid_update" => "ORCID Auto-Update" }
  end

  def state_names
    { 0 => "waiting",
      1 => "working",
      2 => "failed",
      3 => "done",
      4 => "ignored" }
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
    data[:source_id] = @source.name if @source.present? && !@source.is_a?(Array)
    data[:user_id] = current_user.uid if current_user.present?
    data[:sort] = @sort.name if @sort.present?

    { class: "logo", id: "api_key", data: data }
  end
end
