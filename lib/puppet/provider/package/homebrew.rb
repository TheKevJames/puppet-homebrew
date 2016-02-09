Puppet::Type.type(:package).provide(:homebrew,
                                    :parent => :brewcommon,
                                    :source => :brewcommon) do
  desc 'Package management using HomeBrew (+ casks!) on OS X'

  def install
    name = self.build_name
    output = brew(:install, name, *install_options)
    if output =~ /Error: No available formula/
      # Fallback to brewcask
      output = brew(:cask, :install, name, *install_options)

      if output =~ /Error: No available formula/
        raise Puppet::ExecutionFailure, "Could not find package #{name}"
      end
    end
  end

  def uninstall
    brew(:uninstall, @resource[:name])
    brew(:cask, :uninstall, @resource[:name])
  end

  def update
    # Since brew-cask has no upgrade feature built-in, we simply need to
    # uninstall and reinstall
    uninstall
    install
  end

  def self.package_list(options={})
    begin
      if name = options[:justme]
        result = brew(:list, '--versions', name)
        unless result.include? name
          # Of course brew-cask has a different --versions format than brew
          # when getting the version of a single package
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
end
