# Puppet-Homebrew

A Puppet Module to install Homebrew and manage Homebrew packages on Mac OS X.

## Usage

Use the Homebrew package provider like this:

```puppet
class hightower::packages {
  pkglist = ['postgresql', 'nginx', 'git', 'tmux']

  package { $pkglist:
    ensure   => installed,
    provider => brew,
  }
}
```

To install homebrew on a node (with a compiler already present!):

```puppet
class { 'homebrew':
  user => 'hightower',    # Defaults to 'root'
}
```

To install homebrew and a compiler (on Lion or later):

```puppet
class { 'homebrew':
  command_line_tools_package => 'command_line_tools_for_xcode_os_x_lion_aug_2012.dmg',
  command_line_tools_source  => 'http://puppet/command_line_tools_for_xcode_os_x_lion_aug_2012',
}
```

(Please read the fine manual ["Homebrew Installation"](https://github.com/mxcl/homebrew/wiki/Installation) for further epiphany).

Note that you have to download and provide the command line tools yourself, which requires an Apple ID! Sorry, dude.
