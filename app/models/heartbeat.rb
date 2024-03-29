# frozen_string_literal: true

require "timeout"

class Heartbeat
  attr_reader :string, :status

  def initialize
    if services_up?
      @string = "OK"
      @status = 200
    else
      @string = "failed"
      @status = 500
    end
  end

  def services_up?
    memcached_up?
  end

  def memcached_up?
    host = ENV["MEMCACHE_SERVERS"] || ENV["HOSTNAME"]
    memcached_client = Dalli::Client.new("#{host}:11211")
    memcached_client.alive!
    true
  rescue StandardError
    false
  end
end
