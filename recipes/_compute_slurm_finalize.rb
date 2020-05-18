# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: _compute_slurm_finalize
#
# Copyright 2013-2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

ruby_block 'get_compute_nodename' do
  block do
    # Retrieve NodeName from scontrol
    require 'mixlib/shellout'
    cmd = Mixlib::ShellOut.new("/opt/slurm/bin/scontrol show nodes -F | awk \"/\\y$(hostname)\\y/\" RS= | grep -oP '^NodeName=\\K(\\S+)'", :user => 'root')
    cmd.run_command
    node.run_state['slurm_compute_nodename'] = cmd.stdout.strip
    # Raise if NodeName not found
    cmd.error!
  end
  retries 3
  retry_delay 5
end

directory '/etc/sysconfig' do
  user 'root'
  group 'root'
  mode '0755'
end

file '/etc/sysconfig/slurmd' do
  content (lazy { "SLURMD_OPTIONS='-N #{node.run_state['slurm_compute_nodename']}'" })
  mode '0755'
  owner 'root'
  group 'root'
end

service "slurmd" do
  supports restart: true
  action %i[enable start]
end