import json
import socket
from os import makedirs, path

import argparse

from jinja2 import Environment, FileSystemLoader


def generate_slurm_config_files(args):

    with open(args.input_file) as input_file:
        queues_info = json.load(input_file)

    queues_info["master_hostname"] = socket.gethostname()
    # Make output directories
    pcluster_subdirectory = path.join(args.output_directory, "pcluster")
    makedirs(pcluster_subdirectory, exist_ok=True)

    file_loader = FileSystemLoader(args.template_directory)
    env = Environment(loader=file_loader)
    # Generate slurm_parallelcluster_{QueueName}_partitions.conf and slurm_parallelcluster_{QueueName}_gres.conf
    for queue in queues_info["queues_config"]:
        for file_type in ["partition", "gres"]:
            queues_info["queues_config"][queue]["queue_{}_filename".format(file_type)] = path.abspath(
                path.join(
                    pcluster_subdirectory,
                    "slurm_parallelcluster_{}_{}.conf".format(
                        queues_info["queues_config"][queue]["queue_name"], file_type
                    ),
                )
            )
            rendered_template = env.get_template("slurm_parallelcluster_queue_{}.conf".format(file_type)).render(
                queue=queues_info["queues_config"][queue]
            )
            if not args.dryrun:
                filename = queues_info["queues_config"][queue]["queue_{}_filename".format(file_type)]
                _write_rendered_template_to_file(rendered_template, filename)

    # Generate slurm_parallelcluster_partitions.conf and slurm_parallelcluster_gres.conf
    for template_name in ["slurm_parallelcluster.conf", "slurm_parallelcluster_gres.conf"]:
        rendered_template = env.get_template("{}".format(template_name)).render(queues_info)
        if not args.dryrun:
            filename = "{}/{}".format(args.output_directory, template_name)
            _write_rendered_template_to_file(rendered_template, filename)

    print("Done!")


def _write_rendered_template_to_file(rendered_template, filename):
    print("Writing contents of {}".format(filename))
    with open(filename, "w") as output_file:
        output_file.write(rendered_template)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Take in slurm configuration generator related parameters")
    parser.add_argument(
        "--output-directory", type=str, help="The output directory for generated slurm configs", required=True
    )
    parser.add_argument(
        "--template-directory", type=str, help="The directory storing slurm config templates", required=True
    )
    parser.add_argument(
        "--input-file",
        type=str,
        default="/opt/parallelcluster/slurm_config.json",
        help="JSON file containing info about queues",
    )
    parser.add_argument(
        "--dryrun", action="store_true", help="dryrun", required=False, default=False,
    )
    args = parser.parse_args()
    generate_slurm_config_files(args)
