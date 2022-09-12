require "active_stash/assess"
require "active_stash/version"
require "git-version-bump"
require "active_stash/error"
require "active_stash/search"
require "active_stash/validations"
require "active_stash/collection_proxy"
require "active_stash/schema_builder"
require "active_stash/query_builder"
require "active_stash/model_reflection"
require "active_stash/relation"
require "active_stash/index"
require "active_stash/index_dsl"
require "active_stash/index_lookup"
require "active_stash/finalized_index_config"
require "active_stash/logger"
require "active_stash/railtie" if defined?(Rails::Railtie)

require "cipherstash/client"

module ActiveStash
  class Error < StandardError; end

  class Config
    def to_client_opts
      self.instance_values
        .map { |key, value| [key.to_s.camelize(:lower).to_sym, value] }
        .to_h
        .compact
    end
  end

  Config.class_eval do
    attr_accessor *CipherStash::Client.client_options.map { |o| o.to_s.underscore.to_sym }
  end

  def self.config
    @@config ||= Config.new
  end

  def self.configure
    yield self.config
  end
end
