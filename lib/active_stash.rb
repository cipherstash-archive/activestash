require "active_stash/version"
require "active_stash/search"
require "active_stash/schema_builder"
require "active_stash/railtie" if defined?(Rails::Railtie)

# TODO: Temp
require "active_stash/stash"

module ActiveStash
  class Error < StandardError; end
end
