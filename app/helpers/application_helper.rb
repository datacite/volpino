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
    else
      'panel-success'
    end
  end

  def enabled_text
    if !user_signed_in?
      ''
    else
      '<span class="small pull-right">enabled</span>'
    end
  end

  def roles
    %w(user staff admin)
  end
end
