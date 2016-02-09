require 'puppet/provider/package'

Puppet::Type.type(:package).provide(:brewcommon,
                                    :parent => Puppet::Provider::Package) do
  desc 'Base class for brew package management'

  confine  :operatingsystem => :darwin

  has_feature :versionable

  if Puppet::Util::Package.versioncmp(Puppet.version, '3.0') >= 0
    has_command(:brew, '/usr/local/bin/brew') do
      environment({ 'HOME' => ENV['HOME'] })
    end
  else
    commands :brew => '/usr/local/bin/brew'
  end

  def install
    raise Puppet::ExecutionFailure, 'Use brew provider.'
  end

  def uninstall
    raise Puppet::ExecutionFailure, 'Use brew provider.'
  end

  def update
    raise Puppet::ExecutionFailure, 'Use brew provider.'
  end

  def query
    self.class.package_list(:justme => resource[:name])
  end

  def latest
    hash = self.class.package_list(:justme => resource[:name])
    hash[:ensure]
  end

  def self.package_list(options={})
    raise Puppet::ExecutionFailure, 'Use brew provider.'
  end

  def self.name_version_split(line)
    raise Puppet::ExecutionFailure, 'Use brew provider.'
  end

  def self.instances(justme = false)
    package_list.collect { |hash| new(hash) }
  end
end
