Puppet::Type.type(:package).provide(:brew,
                                    :parent => :brewcommon,
                                    :source => :brewcommon) do
  desc 'Package management using HomeBrew on OS X'

  def install
    name = @resource[:name]
    should = @resource[:ensure]

    case should
    when true, false, Symbol
      # pass
    else
      name += "-#{should}"
    end

    if install_options.any?
      output = brew(:install, name, *install_options)
    else
      output = brew(:install, name)
    end

    if output =~ /Error: No available formula/
      raise Puppet::ExecutionFailure, "Could not find package #{name}"
    end
  end

  def uninstall
    brew(:uninstall, @resource[:name])
  end

  def update
    brew(:upgrade, @resource[:name])
  end

  def self.package_list(options={})
    begin
      if name = options[:justme]
        result = brew(:list, '--versions', name)
      else
        result = brew(:list, '--versions')
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
        :provider => :brew
      }
    else
      Puppet.warning "Could not match #{line}"
      nil
    end
  end
end
