class homebrew (
  $user,
  $command_line_tools_package = undef,
  $command_line_tools_source  = undef,
  $github_token               = undef,
  $group                      = 'admin',
  $multiuser                  = false,
) {

  if $::operatingsystem != 'Darwin' {
    fail('This Module works on Mac OSX only!')
  }

  if $homebrew::user == 'root' {
    fail('Homebrew does not support installation as the "root" user.')
  }

  class { '::homebrew::compiler': }
  -> class { '::homebrew::install': }

  contain '::homebrew::compiler'
  contain '::homebrew::install'

  if $homebrew::github_token {
    file { '/etc/environment': ensure => present }
    -> file_line { 'homebrew-github-api-token':
      path  => '/etc/environment',
      line  => "HOMEBREW_GITHUB_API_TOKEN=${homebrew::github_token}",
      match => '^HOMEBREW_GITHUB_API_TOKEN',
    }
  }

}
