#!/usr/bin/env python

import requests
import argparse
import sys
import json

arg_parser = argparse.ArgumentParser(description="Deploy a Docker container.")
arg_parser.add_argument("--registry")
arg_parser.add_argument("--host")
arg_parser.add_argument("--app")
arg_parser.add_argument("--version")
arg_parser.add_argument("--ports", metavar='N', type=int, nargs='+')
args = arg_parser.parse_args()

request_headers = {'content-type': 'application/json'}

def remove_running_container():
	get_running_containers = requests.get("http://" + args.host.strip("http://") + "/containers/json?all=1")
	for container in get_running_containers.json():
		if args.app in container["Image"]:
			kill_container = requests.post("http://" + args.host.strip("http://") + "/containers/" + container["Id"] + "/kill")
			remove_container = requests.delete("http://" + args.host.strip("http://") + "/containers/" + container["Id"])
	pull_image()

def pull_image():
	pull_image = requests.post("http://" + args.host.strip("http://") + "/images/create?fromImage=" + args.registry.strip("http://") + "/" + args.app + "&tag=" + args.version, headers=request_headers) 
	if pull_image.status_code == 200:
		create_container()

def create_container():
	ports = {}
	for port in args.ports:
		ports[str(port) + "/tcp"] = {}
	container_config = { 
    "Name": args.app + ":" + args.version,
    "Cmd":["/sbin/my_init"],
    "ExposedPorts":ports,
    "Image": args.registry.strip("http://") + "/" + args.app + ":" + args.version,
    "DisableNetwork": "false" }
	create_container = requests.post("http://" + args.host.strip("http://") + "/containers/create?name=" + args.app + "-" + args.version, headers=request_headers, data=json.dumps(container_config))
	if create_container.status_code == 201:
		start_container(create_container.json()['Id'])
	elif create_container.status_code == 409:
		sys.exit("ERROR: Container already created.")

def start_container(container_id):
	port_bindings = {"PortBindings":{}}
	for port in args.ports:
		port_bindings["PortBindings"][str(port) + "/tcp"] = [{"HostPort": str(port)}]
	start_container = requests.post("http://" + args.host.strip("http://") + "/containers/" + container_id + "/start", headers=request_headers, data=json.dumps(port_bindings))
	print start_container.status_code

if __name__ == "__main__":
	remove_running_container()