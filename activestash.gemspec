begin
  require "git-version-bump"
rescue LoadError
  nil
end

Gem::Specification.new do |spec|
  spec.name          = "active_stash"
  spec.version       = GVB.version rescue "0.0.0.1.NOGVB"
  spec.date          = GVB.date    rescue Time.now.strftime("%Y-%m-%d")
  spec.authors       = ["Dan Draper", "James Sadler"]
  spec.email         = ["dan@cipherstash.com", "james@cipherstash.com"]

  spec.summary       = %q{Add searchable encryption to your rails models}
  spec.description   = %q{This gem wraps stash.rb so that you can use CipherStash to add searchable encryption to your models}
  spec.homepage      = "https://cipherstash.com/activestash"
  spec.license = "LicenseRef-LICENSE"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/cipherstash/activestash"
  spec.metadata["changelog_uri"] = "https://github.com/cipherstash/activestash/releases"
  spec.metadata["bug_tracker_uri"] = "https://github.com/cipherstash/activestash/issues"
  spec.metadata["documentation_uri"] = "https://rubydoc.info/gems/active_stash"
  spec.metadata["mailing_list_uri"] = "https://discuss.cipherstash.com"

  spec.add_runtime_dependency "cipherstash-client", "~> 0.17.0"
  spec.add_runtime_dependency "activerecord"
  spec.add_runtime_dependency "terminal-table", "~> 3.0"
  spec.add_runtime_dependency "launchy", "~> 2.5"
  spec.add_runtime_dependency "git-version-bump", "~> 0.17"

  if RUBY_VERSION < '3.1'
    # https://github.com/ruby/net-protocol/issues/10
    # https://github.com/rails/rails/pull/44175
    spec.add_runtime_dependency 'net-http', '~> 0.2.2'
  end
  spec.add_development_dependency 'pg'
  spec.add_development_dependency 'rails', '>= 6.0'
  spec.add_development_dependency 'factory_bot', '~> 6.2', '>= 6.2.1'
  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "github-release", "~> 0.2"
  spec.add_development_dependency "lockbox", "~> 1.0"

  spec.files = Dir["CHANGELOG.md", "MIT-LICENSE", "README.md", "lib/**/*"]
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
