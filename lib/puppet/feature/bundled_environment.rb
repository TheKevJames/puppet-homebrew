require "puppet/util/feature"

Puppet.features.add(:bundled_environment) do
  !!(defined?(Bundler) && Bundler.respond_to?(:with_clean_env))
end
