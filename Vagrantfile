# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "chaifeng/ubuntu-18.04-docker-18.09"

  for bash_version in ["4.3", "4.4", "5.0", "devel"] do
    config.vm.provision "Test on Bash-#{bash_version}", type: "shell", inline: <<-SHELL
    set -euo pipefail
    bash_version="#{bash_version}"
    docker run --rm -v /vagrant:/src \
               --name "test-bach-on-bash-${bash_version}" \
               bash:"$bash_version" /src/run-tests.sh
    SHELL
  end
  config.vm.provision "Test Done", type: "shell", inline: <<-SHELL
    echo ======================
    echo Yes, all tests passed.
    echo ======================
  SHELL
end
