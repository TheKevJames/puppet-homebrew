Puppet::Type.type(:package).provide(:homebrew,
                                    :parent => :brewcommon,
                                    :source => :brewcommon) do
  desc 'Package management using HomeBrew (+ casks!) on OS X'

  has_feature :install_options

  def install
    name = install_name

    Puppet.debug "Installing #{name}"
    output = execute([command(:brew), :install, name, *install_options, "2> /dev/null"])

    if output =~ /Searching taps/
      Puppet.debug "Falling back to brew-cask (still installing #{name}"
      output = execute([command(:brew), :cask, :install, name, *install_options, "2> /dev/null"])
      # brewcask includes some funky beer characters that f*ck with encoding
      output = output.encode('UTF-8', :invalid => :replace, :undef => :replace)

      if output.empty?
        raise Puppet::ExecutionFailure, "Could not find package #{name}"
      end
    end

    if output =~ /sha256 checksum/
      Puppet.debug "Fixing checksum error..."
      mismatched = output.match(/Already downloaded: (.*)/).captures
      fix_checksum(mismatched)
    end
  end

  def uninstall
    name = @resource[:name].downcase

    Puppet.debug "Uninstalling #{name}"
    execute([command(:brew), :uninstall, name, "2> /dev/null"])
    execute([command(:brew), :cask, :uninstall, name, "2> /dev/null"])
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
        result = execute([command(:brew), :list, '--versions', name, "2> /dev/null"])
        unless result.include? name
          result = execute([command(:brew), :cask, :list, '--versions', "2> /dev/null"])
        end
      else
        result = execute([command(:brew), :list, '--versions', "2> /dev/null"])
        result += execute([command(:brew), :cask, :list, '--versions', "2> /dev/null"])
      end
      Puppet.debug "Found packages #{result}"
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
