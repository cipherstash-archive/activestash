require "active_stash/version"
require "active_stash/search"
require "active_stash/schema_builder"
require "active_stash/query"
require "active_stash/stash_indexes"
require "active_stash/logger"
require "active_stash/railtie" if defined?(Rails::Railtie)

module ActiveStash
  class Error < StandardError; end
end
