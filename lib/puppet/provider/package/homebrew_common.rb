require 'etc'
require 'puppet/provider/package'

class HomebrewProvider < Puppet::Provider::Package
  def self.brew_binary_config
    return @@brew_binary_config if defined?(@@brew_binary_config)
    ['/opt/homebrew/bin/brew', '/usr/local/bin/brew'].each do |path|
      stat = File.stat(path)
      if stat.executable_real?
        if stat.uid.zero?
          raise Puppet::ExecutionFailure,
            "Homebrew does not support installations owned by the 'root' user. Please check the permissions of #{bin}"
        end
        return @@brew_binary_config = { path: path, uid: stat.uid, gid: stat.gid, home: Etc.getpwuid(stat.uid).dir }
      end
    end
    raise Puppet::ExecutionFailure,
            "Could not find a Homebrew binary"
  end

  def self.with_unbundled_env
    return yield unless Puppet.features.bundled_environment?

    if Bundler.respond_to?(:with_unbundled_env)
      Bundler.with_unbundled_env { yield }
    else
      Bundler.with_clean_env { yield }
    end
  end

  def self.brew_shellenv
    env = {}
    begin
      output = execute(
        [binary[:path], 'shellenv'],
        combine: false,
        merge_brew_env: false,
        failonfail: true
      )

      output.each_line do |line|
        if line =~ /export\s+(\w+)=["']?([^"']*)["']?;?$/
          env[Regexp.last_match(1)] = Regexp.last_match(2)
        end
      end
    rescue Puppet::ExecutionFailure => e
      Puppet.debug("Failed to run brew shellenv: #{e.message}; falling back to minimal environment")
    end
    env
  end

  def self.execute(cmd, failonfail: false, combine: true, merge_brew_env: true)
    env = { 'HOME' => brew_binary_config[:home] }

    if merge_brew_env
      env = env.merge(@@brew_shellenv ||= brew_shellenv)
    end

    with_unbundled_env do
      super(cmd,
            uid: brew_binary_config[:uid],
            gid: brew_binary_config[:gid],
            # Dir.tmpdir doesn't work on MacOS because its parent isn't readable on MacOS, and Homebrew fails in that
            # situation.
            # /tmp works, and is guaranteed to exist on POSIX OSes:
            # https://refspecs.linuxfoundation.org/FHS_3.0/fhs/ch03s18.html
            # https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap10.html#tag_10_01
            cwd: '/tmp',
            combine: combine,
            custom_environment: env,
            failonfail: failonfail)
    end
  end

  def execute(*args, **kwargs)
    self.class.execute(*args, **kwargs)
  end

  def install_options
    Array(resource[:install_options]).flatten.compact
  end

  def resource_name
    return resource[:name] if resource[:name].match?(%r{^https?://})

    resource[:name].downcase
  end

  def install_name
    should = resource[:ensure].downcase

    case should
    when true, false, Symbol
      resource_name
    else
      "#{resource_name}@#{should}"
    end
  end

  def fix_checksum(files)
    files.each { |file| File.delete(file) }
  rescue Errno::ENOENT
    Puppet.warning("Could not remove mismatched checksum files #{files}")
  ensure
    raise Puppet::ExecutionFailure, "Checksum error for package #{name} in files #{files}"
  end
end
