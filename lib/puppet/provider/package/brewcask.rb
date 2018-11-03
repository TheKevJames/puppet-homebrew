require 'puppet/provider/package'

Puppet::Type.type(:package).provide(:brewcask, :parent => Puppet::Provider::Package) do
  desc "Package management using HomeBrew casks on OSX"

  confine :operatingsystem => :darwin

  has_feature :installable
  has_feature :uninstallable
  has_feature :upgradeable
  has_feature :versionable

  has_feature :install_options

  commands :brew => '/usr/local/bin/brew'
  commands :stat => '/usr/bin/stat'

  def self.execute(cmd, failonfail = false, combine = false)
    owner = stat('-nf', '%Uu', '/usr/local/bin/brew').to_i
    group = stat('-nf', '%Ug', '/usr/local/bin/brew').to_i
    home  = Etc.getpwuid(owner).dir

    if owner == 0
      raise Puppet::ExecutionFailure, 'Homebrew does not support installations owned by the "root" user. Please check the permissions of /usr/local/bin/brew'
    end

    # the uid and gid can only be set if running as root
    if Process.uid == 0
      uid = owner
      gid = group
    else
      uid = nil
      gid = nil
    end

    if Puppet.features.bundled_environment?
      Bundler.with_clean_env do
        super(cmd, :uid => uid, :gid => gid, :combine => combine,
              :custom_environment => { 'HOME' => home }, :failonfail => failonfail)
      end
    else
      super(cmd, :uid => uid, :gid => gid, :combine => combine,
            :custom_environment => { 'HOME' => home }, :failonfail => failonfail)
    end
  end

  def self.instances(justme = false)
    package_list.collect { |hash| new(hash) }
  end

  def execute(*args)
    # This does not return exit codes in puppet <3.4.0
    # See https://projects.puppetlabs.com/issues/2538
    self.class.execute(*args)
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

  def resource_name
    if @resource[:name].match(/^https?:\/\//)
      @resource[:name]
    else
      @resource[:name].downcase
    end
  end

  def install_name
    should = @resource[:ensure].downcase

    case should
    when true, false, Symbol
      resource_name
    else
      "#{resource_name}-#{should}"
    end
  end

  def install_options
    Array(resource[:install_options]).flatten.compact
  end

  def latest
    package = self.class.package_list(:justme => resource_name)
    package[:ensure]
  end

  def query
    self.class.package_list(:justme => resource_name)
  end

  def install
    begin
      Puppet.debug "Looking for #{install_name} package..."
      execute([command(:brew), :cask, :info, install_name], :failonfail => true)
    rescue Puppet::ExecutionFailure => detail
      raise Puppet::Error, "Could not find package: #{install_name}"
    end

    begin
      Puppet.debug "Package found, installing..."
      output = execute([command(:brew), :cask, :install, install_name, *install_options], :failonfail => true)

      if output =~ /sha256 checksum/
        Puppet.debug "Fixing checksum error..."
        mismatched = output.match(/Already downloaded: (.*)/).captures
        fix_checksum(mismatched)
      end
    rescue Puppet::ExecutionFailure => detail
      raise Puppet::Error, "Could not install package: #{detail}"
    end
  end

  def uninstall
    begin
      Puppet.debug "Uninstalling #{resource_name}"
      execute([command(:brew), :cask, :uninstall, resource_name], :failonfail => true)
    rescue Puppet::ExecutionFailure => detail
      raise Puppet::Error, "Could not uninstall package: #{detail}"
    end
  end

  def update
    Puppet.debug "Updating #{resource_name}"
    install
  end

  def self.package_list(options={})
    Puppet.debug "Listing installed packages"
    begin
      if resource_name = options[:justme]
        result = execute([command(:brew), :cask, :list, '--versions', resource_name])
        if result.empty?
          Puppet.debug "Package #{resource_name} not installed"
        else
          Puppet.debug "Found package #{result}"
        end
      else
        result = execute([command(:brew), :cask, :list, '--versions'])
      end
      list = result.lines.map {|line| name_version_split(line)}
    rescue Puppet::ExecutionFailure => detail
      raise Puppet::Error, "Could not list packages: #{detail}"
    end

    if options[:justme]
      return list.shift
    else
      return list
    end
  end

  def self.name_version_split(line)
    if line =~ (/^(\S+)\s+(.+)/)
      {
        :name     => $1,
        :ensure   => $2,
        :provider => :brewcask
      }
    else
      Puppet.warning "Could not match #{line}"
      nil
    end
  end
end
