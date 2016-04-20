Facter.add(:has_brew) do
  setcode do
    warn('Unsupported OS.')
    nil
  end
end

Facter.add(:has_brew) do
  confine :operatingsystem => :darwin
  setcode do
    File.exists?('/usr/local/bin/brew') || system('brew --version >/dev/null 2>&1')
  end
end
