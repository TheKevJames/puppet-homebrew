require 'etc'
require 'tmpdir'

module Puppet
  class Provider
    class Package
      module HomebrewCommon
        BREW_PATHS = ['/opt/homebrew/bin/brew', '/usr/local/bin/brew'].freeze

        def self.included(base)
          base.extend(ClassMethods)
        end

        module ClassMethods
          def brewbin
            @brewbin ||= BREW_PATHS.find { |path| File.exist?(path) }
          end

          def with_unbundled_env
            return yield unless Puppet.features.bundled_environment?

            if Bundler.respond_to?(:with_unbundled_env)
              Bundler.with_unbundled_env { yield }
            else
              Bundler.with_clean_env { yield }
            end
          end

          def execution_cwd(home)
            [Dir.tmpdir, '/tmp', home].find do |path|
              path && File.directory?(path) && File.executable?(path) && File.writable?(path)
            end || '/tmp'
          end

          def brew_shellenv(owner, home)
            return @brew_shellenv if defined?(@brew_shellenv)

            begin
              uid, gid = if Process.uid.zero?
                           [owner, stat('-nf', '%Ug', brewbin).to_i]
                         else
                           [nil, nil]
                         end

              output = with_unbundled_env do
                super([brewbin, 'shellenv'],
                      uid: uid,
                      gid: gid,
                      cwd: execution_cwd(home),
                      combine: false,
                      custom_environment: { 'HOME' => home },
                      failonfail: true)
              end

              env = {}
              output.each_line do |line|
                if line =~ /export\s+(\w+)=["']?([^"']*)["']?;?$/
                  env[Regexp.last_match(1)] = Regexp.last_match(2)
                end
              end
              @brew_shellenv = env
            rescue Puppet::ExecutionFailure => e
              Puppet.debug("Failed to run brew shellenv: #{e.message}; falling back to minimal environment")
              @brew_shellenv = {}
            end
          end

          def execute(cmd, failonfail: false, combine: true)
            owner = stat('-nf', '%Uu', brewbin).to_i
            group = stat('-nf', '%Ug', brewbin).to_i
            home = Etc.getpwuid(owner).dir

            if owner.zero?
              raise Puppet::ExecutionFailure,
                    'Homebrew does not support installations owned by the "root" user. Please check the permissions of /usr/local/bin/brew'
            end

            uid, gid = if Process.uid.zero?
                         [owner, group]
                       else
                         [nil, nil]
                       end

            env = { 'HOME' => home }.merge(brew_shellenv(owner, home))

            with_unbundled_env do
              super(cmd,
                    uid: uid,
                    gid: gid,
                    cwd: execution_cwd(home),
                    combine: combine,
                    custom_environment: env,
                    failonfail: failonfail)
            end
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
    end
  end
end
