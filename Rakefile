require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet-lint/tasks/puppet-lint'

task :validate do
  Dir['manifests/**/*.pp'].each do |manifest|
    sh "puppet-lint --no-documentation-check --no-autoloader_layout-check --no-80chars-check #{manifest}"
    sh "puppet parser validate --noop #{manifest}"
  end
end
