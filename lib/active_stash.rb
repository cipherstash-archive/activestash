require "active_stash/version"
require "active_stash/error"
require "active_stash/search"
require "active_stash/collection_proxy"
require "active_stash/schema_builder"
require "active_stash/query_builder"
require "active_stash/reflection"
require "active_stash/relation"
require "active_stash/stash_indexes"
require "active_stash/logger"
require "active_stash/railtie" if defined?(Rails::Railtie)

require "cipherstash/client"

module ActiveStash
  class Error < StandardError; end
end
