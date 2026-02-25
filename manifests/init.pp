class homebrew (
  String[1] $user,
  Optional[String[1]] $command_line_tools_package = undef,
  Optional[String[1]] $command_line_tools_source  = undef,
  Optional[String[1]] $github_token               = undef,
  String[1] $group                                = 'admin',
  Boolean $multiuser                              = false,
) {

  if $facts['os']['name'] != 'Darwin' {
    fail('This module works on macOS only.')
  }

  if $user == 'root' {
    fail('Homebrew does not support installation as the "root" user.')
  }

  contain 'homebrew::compiler'
  contain 'homebrew::install'

  Class['homebrew::compiler']
    -> Class['homebrew::install']

  if $github_token {
    file { '/etc/environment':
      ensure => file,
    }

    file_line { 'homebrew-github-api-token':
      path  => '/etc/environment',
      line  => "HOMEBREW_GITHUB_API_TOKEN=${github_token}",
      match => '^HOMEBREW_GITHUB_API_TOKEN',
    }
  }
}
