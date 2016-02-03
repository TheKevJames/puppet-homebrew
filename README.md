# puppet-homebrew

A Puppet Module to install Homebrew and manage Homebrew packages on Mac OS X.
This module can install using either homebrew or brewcask, aloong with a
fallback mode which attempts both.

## Usage

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

To install homebrew on a node (with a compiler already present!):

```puppet
class { 'homebrew':
  user => 'hightower',    # Defaults to 'root'
}
```

To install homebrew and a compiler (on Lion or later), eg.:

```puppet
class { 'homebrew':
  command_line_tools_package => 'command_line_tools_for_xcode_os_x_lion_april_2013.dmg',
  command_line_tools_source  => 'http://devimages.apple.com/downloads/xcode/command_line_tools_for_xcode_os_x_lion_april_2013.dmg',
}
```

N.B. the author of this module does not maintain a mirror to command_line_tools.
You may need to search for a copy if you use this method. At the time of this
writing, downlaoding the command line tools requires an Apple ID. Sorry, dude!

## Original Author

Original credit for this module goes to
[kelseyhightower](https://github.com/kelseyhightower). This module was forked
to provide brewcask integration.
