module Volpino
  class Application
    g = Git.open(Rails.root)
    begin
      VERSION = g.tags.map { |t| Gem::Version.new(t.name) }.max.to_s
    rescue ArgumentError
      VERSION = "1.0".freeze
    end
    REVISION = g.object("HEAD").sha
  end
end
