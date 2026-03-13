# frozen_string_literal: true

module ApplicationHelper
  def icon(icon, text = nil, html_options = {})
    if text.is_a?(Hash)
      html_options = text
      text = nil
    end

    content_class = "fas fa-#{icon}"
    content_class << " #{html_options[:class]}" if html_options.key?(:class)
    html_options[:class] = content_class

    html = content_tag(:i, nil, html_options)
    html << " " << text.to_s if text.present?
    html
  end

  def devise_current_user
    @devise_current_user ||= warden.authenticate(scope: :user)
  end

  def current_user
    if session[:auth].blank?
      devise_current_user
    else
      uid = session[:auth].fetch("uid", nil)
      User.where(uid: uid).first
    end
  end

  def aasm_states
    ["waiting", "working", "done", "failed", "ignored", "notified"]
  end

  def settings
    Settings[ENV["MODE"]]
  end

  def state_label(state)
    case state
    when "done" then "label-success"
    when "failed" then "label-danger"
    when "working" then "label-info"
    else "label-default"
    end
  end

  def data_tags_for_api
    data = { per_page: 15, model: controller.controller_name, host: ENV["LAGOTTO_URL"] }
    data[:page] = @page if @page.present?
    data[:source_id] = @source.name if @source.present? && !@source.is_a?(Array)
    data[:user_id] = current_user.uid if current_user.present?
    data[:sort] = @sort.name if @sort.present?

    { class: "logo", id: "api", data: data }
  end
end
