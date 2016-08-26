require 'puppet/provider/package'

Puppet::Type.type(:package).provide(:brewcommon,
                                    :parent => Puppet::Provider::Package) do
  desc 'Base class for brew package management'

  confine :operatingsystem => :darwin

  # N.B. feature :install_options is not inheritable
  has_feature :installable, :install_options
  has_feature :uninstallable
  has_feature :upgradeable
  has_feature :versionable

  commands :brew => '/usr/local/bin/brew'
  commands :stat => '/usr/bin/stat'

  def self.execute(cmd)
    owner = stat('-nf', '%Uu', '/usr/local/bin/brew').to_i
    group = stat('-nf', '%Ug', '/usr/local/bin/brew').to_i
    home  = Etc.getpwuid(owner).dir

    ret = super(cmd, :uid => owner, :gid => group, :combine => true,
                :custom_environment => { 'HOME' => home })
    Puppet.debug "Calling command #{cmd}. Got return value: #{ret}"
    ret
  end

  def execute(*args)
    # This does not return exit codes in puppet <3.4.0
    # See https://projects.puppetlabs.com/issues/2538
    self.class.execute(*args)
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

  def fix_checksum(files)
    begin
      for file in files
        File.delete(file)
      end
    rescue Errno::ENOENT
      Puppet.warning "Could not remove mismatched checksum files #{files}"
    end
    raise Puppet::ExecutionFailure, "Checksum error for package #{name} in files #{files}"
  end
end
