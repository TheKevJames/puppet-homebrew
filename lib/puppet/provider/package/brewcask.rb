Puppet::Type.type(:package).provide(:brewcask,
                                    :parent => :brewcommon,
                                    :source => :brewcommon) do
  desc "Package management using HomeBrew casks on OS X"

  has_feature :install_options

  def install
    name = install_name

    Puppet.debug "Installing #{name}"
    output = execute([command(:brew), :cask, :install, name, *install_options])
    # brewcask includes some funky beer characters that f*ck with encoding
    output = output.encode('UTF-8', :invalid => :replace, :undef => :replace)

    if output.empty?
      raise Puppet::ExecutionFailure, "Could not find package #{name}"
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
      result = execute([command(:brew), :cask, :list, '--versions'])
      result = "" if result.include?("Warning: nothing to list")
      if name = options[:justme]
        # Of course brew-cask has a different --versions format than brew when
        # getting the version of a single package
        unless result.empty?
          result = Hash[result.lines.map {|line| line.split}]
          result = result[name] ? name + ' ' + result[name] : ''
        end
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
