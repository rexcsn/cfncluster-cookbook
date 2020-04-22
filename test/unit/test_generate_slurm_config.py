import json
import os

from jsonschema import validate

INPUT_SCHEMA = {
    "type": "object",
    "properties": {
        "queues_config": {
            "type": "object",
            "patternProperties": {
                "^[a-zA-Z0-9-]+$": {
                    "type": "object",
                    "properties": {
                        "queue_name": {"type": "string"},
                        "instances": {
                            "type": "array",
                            "items": {
                                "type": "object",
                                "properties": {
                                    "type": {"type": "string"},
                                    "static_size": {"type": "integer"},
                                    "dynamic_size": {"type": "integer"},
                                    "vcpus": {"type": "integer"},
                                    "gpus": {"type": "integer"},
                                    "spot_price": {"type": "number"},
                                },
                                "additionalProperties": False,
                                "required": ["type", "static_size", "dynamic_size", "vcpus", "gpus"],
                            },
                        },
                        "placement_group": {"type": "string"},
                        "enable_efa": {"type": "boolean"},
                        "disable_hyperthreading": {"type": "boolean"},
                        "compute_type": {"type": "string"},
                    },
                    "additionalProperties": False,
                    "required": ["queue_name", "instances"],
                }
            },
            "additionalProperties": False,
        },
        "scaling_config": {
            "type": "object",
            "properties": {"scaledown_idletime": {"type": "integer"}},
            "required": ["scaledown_idletime"],
        },
    },
    "additionalProperties": False,
    "required": ["queues_config", "scaling_config"],
}


def test_input_file_format():
    filepath = os.path.abspath("files/default/slurm/templates/sample_input.json")
    with open(filepath) as input_file:
        queues_info = json.load(input_file)
        validate(instance=queues_info, schema=INPUT_SCHEMA)
