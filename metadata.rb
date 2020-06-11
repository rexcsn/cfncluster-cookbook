# frozen_string_literal: true

name 'aws-parallelcluster'
maintainer 'Amazon Web Services'
maintainer_email ''
license 'Apache-2.0'
description 'Installs/Configures AWS ParallelCluster'
long_description 'Installs/Configures AWS ParallelCluster'
issues_url 'https://github.com/aws/aws-parallelcluster-cookbook/issues'
source_url 'https://github.com/aws/aws-parallelcluster-cookbook'
chef_version '15.11.8'
version '2.7.0'

supports 'amazon'
supports 'centos', '= 6'
supports 'centos', '= 7'
supports 'ubuntu', '= 16.04'
supports 'ubuntu', '= 18.04'

depends 'poise-python', '~> 1.7.0'
depends 'tar', '~> 2.1.1'
depends 'selinux', '~> 2.1.0'
depends 'nfs', '~> 2.6.3'
depends 'yum', '~> 5.1.0'
depends 'yum-epel', '~> 3.1.0'
depends 'openssh', '~> 2.6.3'
depends 'apt', '~> 7.0.0'
depends 'hostname', '~> 0.4.2'
depends 'line', '~> 2.4.1'
depends 'ulimit', '~> 1.0.0'
# when changing pyenv version, check if pyenv.sh.rb template is still valid
depends 'pyenv', '~> 3.1.0'
