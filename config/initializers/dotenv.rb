# frozen_string_literal: true

# Check for required ENV variables, can be set in .env file
# ENV_VARS is hash of required ENV variables
env_vars = %w{JWT_PRIVATE_KEY JWT_PUBLIC_KEY}
env_vars.each { |env| fail ArgumentError,  "ENV[#{env}] is not set" if ENV[env].blank? }
ENV_VARS = env_vars.index_with { |env| ENV[env] }
