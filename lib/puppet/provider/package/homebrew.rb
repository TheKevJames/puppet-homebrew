require 'puppet/provider/package'

Puppet::Type.type(:package).provide(:homebrew,
                                    :parent => Puppet::Provider::Package) do
  desc 'Package management using HomeBrew (+ casks!) on OS X'

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
    should = @resource[:ensure]

    package_name = @resource[:name]
    case should
    when true, false, Symbol
      # pass
    else
      package_name += "-#{should}"
    end

    output = brew(:install, package_name)

    # Fallback to brewcask
    if output =~ /Error: No available formula/
      output = brew(:cask, :install, package_name)

      # Fail hard if there is no formula available.
      if output =~ /Error: No available formula/
        raise Puppet::ExecutionFailure, "Could not find package #{package_name}"
      end
    end
  end

  def uninstall
    brew(:uninstall, @resource[:name])
    brew(:cask, :uninstall, @resource[:name])
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
        result = brew(:list, '--versions', name)
        unless result.include? name
          # Of course brew-cask has a different --versions format than brew when
          # getting the version of a single package
          result = brew(:cask, :list, '--versions')
          result = Hash[result.lines.map {|line| line.split}]
          result = name + ' ' + result[name]
        end
      else
        result = brew(:list, '--versions')
        result += brew(:cask, :list, '--versions')
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
        :provider => :homebrew
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
