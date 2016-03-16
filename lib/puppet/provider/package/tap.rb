Puppet::Type.type(:package).provide(:tap,
                                    :parent => :brewcommon,
                                    :source => :brewcommon) do
  desc 'Tap management using HomeBrew on OS X'

  def install
    name = @resource[:name]
    output = execute([command(:brew), :tap, name, *install_options])

    if output =~ /Error: Invalid tap name/
      raise Puppet::ExecutionFailure, "Could not find tap #{name}"
    end
  end

  def uninstall
    execute([command(:brew), :untap, @resource[:name]])
  end

  def update
    raise Puppet::ExecutionFailure, "Can not re-tap #{@resource[:name]}"
  end

  def self.package_list(options={})
    begin
      taps = []
      output = execute([command(:brew), :tap])
      output.each_line do |line|
        line.chomp!
        if name = options[:justme]
          return { :name => line, :ensure => 'present', :provider => 'tap' } if line == name
        else
          next if lint.empty?
          taps << new({ :name => line, :ensure => 'present', :provider => 'tap' })
        end
      end
      taps
    rescue Puppet::ExecutionFailure => detail
      raise Puppet::Error, "Could not list taps: #{detail}"
    end
  end
end
