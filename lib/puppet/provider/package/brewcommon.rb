require 'puppet/provider/package'

Puppet::Type.type(:package).provide(:brewcommon,
                                    :parent => Puppet::Provider::Package) do
  desc 'Base class for brew package management'

  confine  :operatingsystem => :darwin

  has_feature :installable, :install_options
  has_feature :uninstallable
  has_feature :upgradeable
  has_feature :versionable

  if Puppet::Util::Package.versioncmp(Puppet.version, '3.0') >= 0
    commands :stat => '/usr/bin/stat'
    owner = stat('-nf', '%Uu', '/usr/local/bin/brew').to_i
    has_command(:brew, '/usr/local/bin/brew') do
      environment({ 'HOME' => Etc.getpwuid(owner).dir })
    end
  else
    commands :brew => '/usr/local/bin/brew'
  end

  def install
    raise Puppet::ExecutionFailure, 'Use brew provider.'
  end

  def install_name
    name = @resource[:name]
    should = @resource[:ensure]

    case should
    when true, false, Symbol
      name
    else
      name + "-#{should}"
    end
  end

  def install_options
    Array(resource[:install_options]).flatten.compact
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
