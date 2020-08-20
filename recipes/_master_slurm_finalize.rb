# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: _master_slurm_finalize
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

execute 'initialize compute fleet status' do
  # Initialize the status of the compute fleet in the DynamoDB table. Set it to RUNNING.
  command "#{node['cfncluster']['cookbook_virtualenv_path']}/bin/aws dynamodb put-item --table-name #{node['cfncluster']['cfn_ddb_table']}"\
          " --item '{\"Id\": {\"S\": \"COMPUTE_FLEET\"}, \"Status\": {\"S\": \"RUNNING\"}}' --region #{node['cfncluster']['cfn_region']}"
  retries 3
  retry_delay 5
end

ruby_block "submit dynamic fleet initialization jobs" do
  block do
    require 'json'
    require 'chef/mixin/shell_out'
    require 'shellwords'

    cluster_config = JSON.parse(File.read(node['cfncluster']['cluster_config_path']))
    cluster_config["cluster"]["queue_settings"].each do |queue_name, queue_config|
      queue_config["compute_resource_settings"].each_value do |instance_config|
        required_dynamic = instance_config.fetch("initial_count", 0) - instance_config.fetch("min_count", 0)
        if required_dynamic.positive?
          # Submitting a job for each instance type that requires an initial_count > min_count
          submit_job_command = Shellwords.escape("/opt/slurm/bin/sbatch --wrap 'sleep infinity' --job-name=parallelcluster-init-cluster "\
                                                 "--constraint='[(dynamic&#{instance_config['instance_type']})*#{required_dynamic}]' --partition=#{queue_name}")
          shell_out!("/bin/bash -c #{submit_job_command}")
        end
      end
    end
  end
end

ruby_block "wait for static fleet capacity" do
  block do
    require 'chef/mixin/shell_out'
    require 'shellwords'

    # Example output for sinfo
    # $ /opt/slurm/bin/sinfo -N -h -o '%N %t'
    # ondemand-dynamic-c5.2xlarge-1 idle~
    # ondemand-dynamic-c5.2xlarge-2 idle~
    # spot-dynamic-c5.xlarge-1 idle~
    # spot-static-t2.large-1 down
    # spot-static-t2.large-2 idle
    is_fleet_ready_command = Shellwords.escape("set -o pipefail && /opt/slurm/bin/sinfo -N -h -o '%N %t' | { grep '\\-static\\-' || true; } | { grep -v -E '(idle|alloc|mix)$' || true; }")
    until shell_out!("/bin/bash -c #{is_fleet_ready_command}").stdout.strip.empty?
      Chef::Log.info("Waiting for static fleet capacity provisioning")
      sleep(15)
    end
    Chef::Log.info("Static fleet capacity is ready")
  end
end

ruby_block "wait for dynamic fleet capacity" do
  block do
    require 'chef/mixin/shell_out'
    require 'shellwords'

    # $ /opt/slurm/bin/squeue --name='init-cluster' -O state -h
    # CONFIGURING
    # RUNNING
    are_jobs_running_command = Shellwords.escape("set -o pipefail && /opt/slurm/bin/squeue --name='init-cluster' -O state -h | { grep -v 'RUNNING' || true; }")
    until shell_out!("/bin/bash -c #{are_jobs_running_command}").stdout.strip.empty?
      Chef::Log.info("Waiting for dynamic fleet capacity provisioning")
      sleep(15)
    end
    Chef::Log.info("Dynamic fleet capacity is ready")
    shell_out!("/opt/slurm/bin/scancel --jobname=parallelcluster-init-cluster")
  end
end
