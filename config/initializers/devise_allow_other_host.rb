# frozen_string_literal: true

module Devise
  module Controllers
    module Helpers
      def redirect_to(options = {}, response_options = {})
        if options.is_a?(String) && options.match?(/\Ahttps?:\/\//)
          response_options[:allow_other_host] = true
        end
        super(options, response_options)
      end
    end
  end
end
