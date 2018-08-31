# puppet-homebrew

A Puppet Module to install Homebrew and manage Homebrew packages on Mac OSX.
This module can install using either homebrew or brewcask, along with a
fallback mode which attempts both.

This module supports Puppet version 4 and greater running on Ruby version 1.8.3
and greater. Note that versions of Ruby from 2.0.x to 2.2.x may no longer be
supported by Homebrew. For Puppet 3 support, please pin to version 1.7.1.

puppet-homebrew is available on the
[Puppet Forge](https://forge.puppetlabs.com/thekevjames/homebrew).

## Usage

### Installing packages

Use the Homebrew package provider like this:

```puppet
class hightower::packages {
  pkglist = ['postgresql', 'nginx', 'git', 'tmux']

  package { $pkglist:
    ensure   => present,
    provider => brew,
  }
}
```

The providers works as follows:
* `provider => brew`: install using `brew install <module>`. Do not use
brewcask.
* `provider => brewcask`: install using `brew cask install <module>`. Only use
brewcask.
* `provider => homebrew`: attempt to install using `brew install <module>`. On
failure, use `brew cask install <module>`

### Tapping repositories

To tap into new Github repositories, simply use the tap provider:

```puppet
package { 'neovim/neovim':
  ensure   => present,
  provider => tap,
}
```

You can untap a repository by setting ensure to `absent`.

#### Ordering taps

When both tapping a repo and installing a package from that repository, it is
important to make sure the former happens first. This can be accomplished in a
few different ways: either by doing so on a per-package basis:

```puppet
package { 'neovim/neovim':
  ensure   => present,
  provider => tap,
} ->
package { 'neovim':
  ensure   => present,
  provider => homebrew,
}
```

or by setting all taps to occur before all other usages of this package with
[Resource Collectors](https://docs.puppet.com/puppet/latest/reference/lang_collectors.html):

```puppet
# pick whichever provider(s) are relevant
Package <| provider == tap |> -> Package <| provider == homebrew |>
Package <| provider == tap |> -> Package <| provider == brew |>
Package <| provider == tap |> -> Package <| provider == brewcask |>
```

### Installing brew

To install homebrew on a node (with a compiler already present!):

```puppet
class { 'homebrew':
  user      => 'hightower',
  group     => 'developers',  # defaults to 'admin'
  multiuser => false,         # set to true to enable multiuser support for homebrew
}
```

Installing homebrew as the root user is no longer supported (as of late 2016).
Please ensure you install brew as a standard (non-root) user.

Note that some users have reported confusion between the *puppet* user and the
*homebrew* user -- it is perfectly fine to run puppet as root, in fact this is
encouraged, but the homebrew user must be non-root (generally, the system's main
user account).

If you run puppet as a non-root user and set the `homebrew::user` to a
*different* non-root user, you may run into issues; namely, since this module
requires the puppet user act as the homebrew user, you may get a password
prompt on each run. This can be fixed by allowing the puppet user passwordless
sudo privileges to the homebrew user.

If you are looking for a multi-user installation, please be sure to set the
multi-user flag, eg.:

```puppet
class { 'homebrew':
  user      => 'kevin',
  group     => 'all-users',
  multiuser => true,
}
```

To install homebrew and a compiler (on Lion or later), eg.:

```puppet
class { 'homebrew':
  user                       => 'kevin',
  command_line_tools_package => 'command_line_tools_for_xcode_os_x_lion_april_2013.dmg',
  command_line_tools_source  => 'http://devimages.apple.com/downloads/xcode/command_line_tools_for_xcode_os_x_lion_april_2013.dmg',
}
```

N.B. the author of this module does not maintain a mirror to command_line_tools.
You may need to search for a copy if you use this method. At the time of this
writing, downloading the command line tools sometimes requires an Apple ID.
Sorry, dude!

#### Adding a Github Token

Homebrew uses a Github token in your environment to make your experience better
by:

- Reducing the rate limit on `brew search` commands
- Letting you tap your private repositories
- Allowing you to upload Gists of brew installation errors

To enable this feature, you can include:

```puppet
class { 'homebrew':
  user         => 'kevin',
  github_token => 'MyT0k3n!',
}
```

Click
[here](https://github.com/settings/tokens/new?scopes=&description=Homebrew) to
create a personal access token for Github.

## Original Author

Original credit for this module goes to
[kelseyhightower](https://github.com/kelseyhightower). This module was forked
to provide brewcask integration.

Credit for logic involved in tapping repositories goes to
[gildas](https://github.com/gildas/puppet-homebrew).
