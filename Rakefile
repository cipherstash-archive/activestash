exec(*(["bundle", "exec", $PROGRAM_NAME] + ARGV)) if ENV['BUNDLE_GEMFILE'].nil?

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

spec = Bundler.load_gemspec("activestash.gemspec")
require "rubygems/package_task"

Gem::PackageTask.new(spec) { |pkg| }

namespace :gem do
  desc "Push all freshly-built gems to RubyGems"
  task :push do
    Rake::Task.tasks.select { |t| t.name =~ %r{^pkg/#{spec.name}-.*\.gem} && t.already_invoked }.each do |pkgtask|
      sh "gem", "push", pkgtask.name
    end
  end
end

task :git_release do
  sh "git release"
end
