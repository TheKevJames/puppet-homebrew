# Facts: has_brew, brew_prefix
#
# Purpose:
# - check if brew is installed
# - check where brew is installed
#
# Resolution:
#   Tests for presence of brew, returns boolean
#   No value set if not on Darwin
#
# Caveats:
#   none
#
# Notes:
#   None


Facter.add(:brew_prefix) do
  confine :operatingsystem => 'Darwin'
  if Facter.value(:os)['architecture'] == 'arm64'
    setcode do
      '/opt/homebrew'
    end
  else
    setcode do
      '/usr/local'
    end
  end
end

Facter.add(:has_brew) do
  confine :operatingsystem => 'Darwin'
  setcode do
    File.exists?(Facter.value(:brew_prefix) + '/bin/brew') or system('brew --version >/dev/null 2>&1')
  end
end
