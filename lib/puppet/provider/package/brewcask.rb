require 'puppet/provider/package'

Puppet::Type.type(:package).provide(:brewcask, :parent => Puppet::Provider::Package) do
  desc "Package management using HomeBrew Cask on OS X"

  confine  :operatingsystem => :darwin

  has_feature :versionable

  # Fix Puppet 3.0 #16779, pass $HOME to brew-cask command.
  if Puppet::Util::Package.versioncmp(Puppet.version, '3.0') >= 0
    has_command(:brewcask, "/usr/local/bin/brew-cask") do
      environment({ 'HOME' => ENV['HOME'] })
    end
  else
    commands :brewcask => "/usr/local/bin/brew-cask"
  end

  # Install packages, known as formulas, using brew-cask.
  def install
    should = @resource[:ensure]

    package_name = @resource[:name]
    case should
    when true, false, Symbol
      # pass
    else
      package_name += "-#{should}"
    end

    output = brewcask(:install, package_name)

    # Fail hard if there is no formula available.
    if output =~ /Error: No available formula/
      raise Puppet::ExecutionFailure, "Could not find package #{@resource[:name]}"
    end
  end

  def uninstall
    brewcask(:uninstall, @resource[:name])
  end

  def update
    self.install
  end

  def query
    self.class.package_list(:justme => resource[:name])
  end

  def latest
    hash = self.class.package_list(:justme => resource[:name])
    hash[:ensure]
  end

  def self.package_list(options={})
    begin
      if name = options[:justme]
        result = brewcask(:list, '--versions', name)
      else
        result = brewcask(:list, '--versions')
      end
      list = result.lines.map {|line| name_version_split(line) }
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
      name = $1
      version = $2
      {
        :name     => name,
        :ensure   => version,
        :provider => :brewcask
      }
    else
      Puppet.warning "Could not match #{line}"
      nil
    end
  end

  def self.instances(justme = false)
    package_list.collect { |hash| new(hash) }
  end
end
