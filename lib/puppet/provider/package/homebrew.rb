Puppet::Type.type(:package).provide(:homebrew,
                                    :parent => :brewcommon,
                                    :source => :brewcommon) do
  desc 'Package management using HomeBrew (+ casks!) on OS X'

  has_feature :install_options

  def install
    name = install_name

    begin
      Puppet.debug "Looking for #{name} package on brew..."
      output = execute([command(:brew), :info, name])
      if output.empty?
         Puppet.debug "Package #{name} not found on Brew. Trying BrewCask..."
         output = execute([command(:brew), :cask, :info, name], failonfail: true)
         Puppet.debug "Package found on brewcask, installing..."
         output = execute([command(:brew), :cask, :install, name, *install_options], failonfail: true)
      else
        Puppet.debug "Package found, installing..."
        output = execute([command(:brew), :install, name, *install_options], failonfail: true)
        if output =~ /sha256 checksum/
          Puppet.debug "Fixing checksum error..."
          mismatched = output.match(/Already downloaded: (.*)/).captures
          fix_checksum(mismatched)
        end
      end
    rescue Puppet::ExecutionFailure => detail
      raise Puppet::Error, "Could not install package: #{detail}"
    end
  end

  def uninstall
    name = @resource[:name].downcase

    Puppet.debug "Uninstalling #{name}"
    execute([command(:brew), :uninstall, name])
    execute([command(:brew), :cask, :uninstall, name])
  end

  def update
    name = @resource[:name].downcase

    Puppet.debug "Updating #{name}"
    install
  end

  def self.package_list(options={})
    Puppet.debug "Listing installed packages"
    begin
      if name = options[:justme]
        result = execute([command(:brew), :list, '--versions', name])
        unless result.include? name
          result += execute([command(:brew), :cask, :list, '--versions', name])
        end
        if result.empty?
          Puppet.debug "Package #{result} not installed"
        else
          Puppet.debug "Found package #{result}"
        end
      else
        result = execute([command(:brew), :list, '--versions'])
        result += execute([command(:brew), :cask, :list, '--versions'])
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
