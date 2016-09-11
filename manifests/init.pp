# == Class: homebrew
#
# This class is able to install and configure homebrew and brew cask.
#
# === Parameters
#
# [*user*]
#   User owner of the brew files and folders.
#   Defaults to nothing.
#
# [*group*]
#   Group owner of the brew files
#   Defaults to `admin`.
#
# [*command_line_tools_package*]
#   URL for the command line tools package.
#   Defaults to `undef`.
#
# [*command_line_tools_source*]
#   name of the dmg file containing the installer for the command line tools
#   package.
#   Defaults to `undef`.
#
# === Original Author
# Original credit for this module goes to
# [kelseyhightower](https://github.com/kelseyhightower). This module was forked
# to provide brewcask integration.
#
# === Contributers
# Kevin James <KevinJames@thekev.in>
# Jordi Garcia <jordi@jordigarcia.net>
#
# === Copyright
#
# Copyright 2015-Present Kevin James, unless otherwise noted.
#
# Credit for logic involved in tapping repositories goes to
# [gildas](https://github.com/gildas/puppet-homebrew).
#
class homebrew (
  $user = $brew::params::user,
  $group = $brew::params::group,
  $command_line_tools_package = $brew::params::command_line_tools_package,
  $command_line_tools_source  = $brew::params::command_line_tools_source
) inherits ::homebrew::params {
  anchor { '::homebrew::begin': }  ->
  class { '::homebrew::compiler': } ->
  class { '::homebrew::install': }  ->
  anchor { '::homebrew::end': }
}
