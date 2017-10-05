#!/usr/bin/env ruby

require 'json'
require 'net/http'
require 'uri'
require 'csv'
require 'thor'

## Script to interact with the NetBox API
#
# Uses Thor to manage input
# 
# Example:
# 
# ruby NetboxClient.rb dns_combine
#

## Class to call the Netbox API and get various results
# Token is passed in an Environment Variable
# export token=.......
# The netbox URL can optionally be passed in an environment variable as well
# export netbox_url=http://...
# Takes an optional "options" hash which is passed to the API request
# The default options hash returns all results without filtering
class NetboxClient < Thor
	@@token = ENV['token']
	if ENV['netbox_url'].nil? 
		@@base_url = 'localhost'
	else
		@@base_url = ENV['netbox_url']
	end
	@@http_options = {'limit' => 0, 'offset' => 0}


	# Send a GET request
	# Return: Array
	desc "get path ...options, base_url", "Send a GET Request"
	method_option :getspeak, :desc => "Print the output here"
	def get(path, http_options = nil, base_url = nil)
		speak = options[:getspeak]
		http_options = @@http_options if http_options.nil?
		unless http_options.instance_of?(Hash)
			return nil
		end
		base_url = @@base_url if base_url.nil?
		http_options = URI.encode_www_form(http_options)
		url = "http://#{base_url}/api/#{path}/?#{http_options}"
		uri = URI.parse(url)
		response = Net::HTTP.get_response(uri)
		results = JSON.parse(response.body)['results']
		if response.code == '200'
			puts results if speak
			misarray(results)
		else
		  puts "Invalid response #{response.code}"
		end
	end

	# Send a POST request
	# Return: HTTP Response Body
	desc "post path post_body", "Send a POST Request"
	method_option :postspeak, :desc => "Print the output here"
	def post(path, post_body, base_url = nil)
		if @@token.nil?
			puts "Token is required"
			exit
		end
		speak = options[:postspeak]
		base_url = @@base_url if base_url.nil?
		url = "http://#{base_url}/api/#{path}/"
		uri = URI.parse(url)
		http = Net::HTTP.new(uri.host, uri.port)
		req = Net::HTTP::Post.new(uri.request_uri)
		req['Content-Type'] = 'application/json'
		req['Accept'] = 'application/json'
		req['Authorization'] = "Token #{@@token}"
		req.body = post_body.to_json
		results = http.request(req).body
		if speak
			puts results
		else
			results
		end
	end

	# Send a PATCH request
	# Return: HTTP Response Body
	desc "patch ...path", "Send a PATCH Request"
	method_option :patchspeak, :desc => "Print the output here"
	def patch(path, id, post_body)
		if @@token.nil?
			puts "Token is required"
			exit
		end
		speak = options[:patchspeak]
		url = "http://#{@@base_url}/api/#{path}/#{id}/"
		uri = URI.parse(url)
		http = Net::HTTP.new(uri.host, uri.port)
		req = Net::HTTP::Patch.new(uri.request_uri)
		req['Content-Type'] = 'application/json'
		req['Accept'] = 'application/json'
		req['Authorization'] = "Token #{@@token}"
		req.body = post_body.to_json
		results = http.request(req).body
		if speak
			puts results
		else
			results
		end
	end

	# Add a virtual machine
	# 
	# Assumes Active status
	# Assumes Centos platform
	# 
	# Returns: HTTP Status Code
	desc "add_virtual_machine name clusterid", "Add a Virtual Machine with name and clusterid"
	def add_virtual_machine(name, clusterid)
		path = 'virtualization/virtual-machines'
		post_body = {
								name: name,
								status: 1,
								cluster: clusterid,
								platform: 2
							}
		post(path, post_body)
	end

	# Bulk Add Virtual Machines
	# 
	# 
	# Returns: HTTP Status Code
	desc "bulk_add_virtual_machines filename", "Bulk add VM's from a File"
	def bulk_add_virtual_machines(filename)
		listof = File.readlines(filename)
		listof.each do |vm|
			array = vm.split(',')
			name = array[0]
			clusterid = array[1]
			# Get the vmid of the vm with name
			#vm_id = get_vm_id_from_name(name)
			# Create the IP address - pass as an array
			#response = add_ip_address(ip)
			#ip_id = JSON.parse(response)['id']
			# Set the IP to the Virtual Machine
			add_virtual_machine(name, clusterid)
		end
	end

	# Update a virtual machine's Primary IP address
	# 
	# Returns: HTTP Status Body
	desc "update_virtual_machine_ip vm_id ip_id", "Update Virtual Machine IP"
	def update_virtual_machine_ip(vm_id, ip_id)
		path = 'virtualization/virtual-machines'
		post_body = {
								primary_ip4: ip_id,
							}
		patch(path, vm_id, post_body)
	end

	# Add a virtual machine interface for each virtual machine
	# 
	# Use case:
	# There's not one by default and all of my VM's are on eth0
	# 
	# Assumes Virtual Interface
	# Assumes Interface is Enabled
	# 
	# Returns: HTTP Status Code
	desc "bulk_add_virtual_machine_interface interface", "Add Virtual Machine Interfaces in Bulk"
	def bulk_add_virtual_machine_interface(interface)
		path = 'virtualization/virtual-machines'
		vms = get(path)
		vms.each do |vm|
			vm_id = vm['id']
			post_body = {
						  "name": interface,
						  "virtual_machine": vm_id,
						  "form_factor": 0,
						  "enabled": true
							}
			path = 'virtualization/interfaces'
			post(path, post_body)
		end
	end

	# Add an IP to a list of Virtual Machines
	# 
	# Use case:
	# I have a long list of VM's and I don't want to set their
	# IP's manually
	# 
	# File is comma-seperated hostname,ip
	# 
	# Returns: HTTP Status Code
	desc "bulk_set_virtual_machine_ip filename interface", "Set Virtual Machine IP's in Bulk"
	def bulk_set_virtual_machine_ip(filename, interface)
		listof = File.readlines(filename)
		listof.each do |vm|
			array = vm.split(',')
			name = array[0]
			ip = array[1]
			# Get the vmid of the vm with name
			vm_id = get_vm_id_from_name(name)
			# Create the IP address - pass as an array
			response = add_ip_address(ip)
			ip_id = JSON.parse(response)['id']
			# Set the IP to the Virtual Machine
			update_virtual_machine_ip(vm_id, ip_id)
		end
	end

	# Get a Virtual Machine ID from it's name
	# 
	# Returns: Integer
	desc "get_vm_id_from_name name", "Set Virtual Machine IP's in Bulk"
	def get_vm_id_from_name(name)
		path = 'virtualization/virtual-machines'
		http_options = { 'name': name }
		vm = get(path, http_options)
		vm[0]['id']
	end

	# Add an IP address
	# 
	# Assumes Active
	#
	# Returns: HTTP Status Code
	desc "add_ip_address ip", "Set Virtual Machine IP's"
	def add_ip_address(ip)
		path = 'ipam/ip-addresses'
		post_body = {
						"address": ip,
						"status": 1
		}
		post(path, post_body)
	end

	# Get an IP address
  #
  #
  # Returns: String
  desc "get_ip_address hostname", "Get the IP of a hostname"
	def get_ip_address(hostname)
		begin
  		IPSocket.getaddress(hostname)
  	rescue SocketError
			false # Can return anything you want here
		end
	end	

	# Get a list of devices on a Rack
	# 
	# Returns: Array
	desc "get_devices_by_rack rack_id", "Get a list of devices on a Rack"
	def get_devices_by_rack(rack_id)
		path = 'dcim/devices'
		rack_options = { 'rack_id': rack_id }
		get(path, rack_options)
	end

	# Get the size of a device by ID
	# 
	# Returns: Integer
	desc "get_size_by_device_name device_name", "Get the size of a device by Name"
	def get_size_by_device_name(device_name)
		path = 'dcim/devices'
		device_name = { "name": device_name }
		device = get(path, device_name)
		device_type_id = device['device_type']['id']
		path = 'dcim/device-types'
		device_type_options = { "id__in": device_type_id }
		device_type = get(path, device_type_options)
		device_type['u_height']
	end

	################################# DNS ####################################
	#
	# Each method returns an array of hosts, ips, service names, and ips


	# Gets all of the Virtual machines hosts, ips and related services
	# This is hacky since we're running 2.2 beta
	# Once PR is merged this can be removed in favor of default method
	# 
	# Optional limit argumument to limit the number of results given
	# 
	# Returns: Array
	desc "dns_vms limit", "Get DNS Information for VM's"
	method_option :dnsvmsspeak, :aliases => '-s', :desc => "Print the output here"
	def dns_vms(limit = 0)
		speak = options[:dnsvmsspeak]
		array = Array.new
		path = 'virtualization/virtual-machines'
		http_options = {'status' => 1, 'limit' => limit, 'offset' => 0}
		vms = get(path, http_options)
		vms.each do |vm|
			hash = Hash.new
			vm_id = vm['id']
			hash['name'] = vm['name']
			# Get IP address by getting the IP ID
			ip_id = vm['primary_ip4']
			unless ip_id.nil?
				ip_options = {'id__in' => ip_id}
				ipam = get("ipam/ip-addresses",ip_options)
				hash['ip'] = ipam[0]['address'].split(/\//).first
			end
			hash['type'] = 'A'
			# Get the services associated with this VM
			vm_options = {'virtual_machine_id' => vm_id}
			services = get("ipam/services", vm_options)
			unless services.nil?
				services.each do |service|
					if service['ipaddresses'].empty?
						ip = service['description']
						hash['servicetype'] = 'CNAME'
					else
						ip = service['ipaddresses'][0]['address'].split(/\//).first
						hash['servicetype'] = 'A'
					end
					hash['servicename'] = service['name']
					hash['serviceip'] = ip
				end
			end
			array << hash
		end
		if speak
			puts array.inspect
		else
			array
		end
	end

	# Returns node names, ips, and related service names and ips for use in order
	# to populate DNS
	# 
	# Optional limit argumument to limit the number of results given
	# 
	# Returns: Array
	desc "dns_physical ...limit", "Get DNS Information for Physical Nodes"
	def dns_physical(limit = 1)
		array = Array.new
		path = 'dcim/devices'
		device_options = {'status' => 1, 'limit' => limit, 'offset' => 0}
		devices = get(path, device_options)
		devices.each do |device|
			unless device['primary_ip'].nil?
				hash = Hash.new
				hash['name'] = device['name']
				hash['ip'] = device['primary_ip']['address'].split(/\//).first
				hash['type'] = 'A'
				service_options = {'device_id' => device['id']}
				services = get("ipam/services",service_options)
				unless services.nil?
					services.each do |service|
						if service['ipaddresses'].empty?
							ip = service['description']
							hash['servicetype'] = 'CNAME'
						else
							ip = service['ipaddresses'][0]['address'].split(/\//).first
							hash['servicetype'] = 'A'
						end
						hash['servicename'] = service['name']
						hash['serviceip'] = ip
					end
				end
			end
			array << hash
		end
		array
	end

	# Combine Virtual Machines and Hardware Device DNS Information into a single array
	# 
	# Returns: True, Writes to CSV
	desc "dns_combine limit", "Export DNS Information for Hosts"
	def dns_combine(limit = 0)
		filename='data.csv'
		# Clean up the old file jic
		File.delete(filename) if File.exist?(filename)
		vms = dns_vms(limit)
		physical = dns_physical(limit)
		array = [*vms,*physical]
		array.each do |d|
			open(filename, 'a+') { |f| f << "#{d['name']},#{d['ip']},#{d['type']}\n" }
			if d['servicename']
				open(filename, 'a+') { |f| f << "#{d['servicename']},#{d['serviceip']},#{d['servicetype']}\n" }
			end
		end
		# De-duplicate services
		dups = File.readlines(filename)
		unqd = dups.uniq
		unqd = unqd.sort
		File.open(filename, 'w') { |f| f << "name,ip,type\n" }
		File.open(filename, "a+") do |f|
  		f.puts(unqd)
		end
		true
	end

	##################### VISUALIZATIONS ####################
	
	# SVG Build
	# 
	# Assumes all Racks are the same size
	# TODO: Don't assume
	# 
	# Returns: String
	no_tasks do
		# Misarray
		# 
		# If an array of hashes has only a single entry we should return only the hash
		# 
		# Returns: Array or Hash
		def misarray(array)
			if array.count == 1
				array[0]
			else
				array
			end
		end


		# Builds an SVG String from an Array
		# 
		# For now this is only used to build Racks since it's very specific
		# 
		# TODO: Add a config file to store the Visualization preferences
		# 
		# Returns: String
		def svgbuild_rack(array)
			u_height = 15
			rack_usize = array[0]['u_height']
			rack_height = u_height * rack_usize
			rack_width = 175
			head_space = 50  # The space between the Racks and the top of the canvas
			rack_space = 25  # The space between Racks
			canvas_width = rack_width * array.count + rack_space * array.count + rack_space * 2
			canvas_height = rack_height + 50
			
			# Canvas
			svgarray = ["<svg width='#{canvas_width}' height='#{canvas_height}' style='background: white' xmlns='http://www.w3.org/2000/svg'>"]
			
			# Start coordinates for drawing
			x = rack_space
			y = head_space
			# Draw the racks
			array.each do |rack|
				svgarray.push("<!-- Rack Name: #{rack['name']} --\>")
				svgarray.push("<rect id='#{rack['id']}' height='#{rack_height}' width='#{rack_width}' y='#{y}' x='#{x}' stroke='#000' stroke-width='1' fill='#fff'/>")
				text_location = x + rack_width * 0.3
				svgarray.push("<text id='#{rack['id']}' xml:space='preserve' text-anchor='start' font-family='Helvetica, Arial, sans-serif' font-size='20' y='#{y - 5}' x='#{text_location}' stroke-width='0' stroke='#000' fill='#000000'>#{rack['name']}</text>")
				devices_on_this_rack = get_devices_by_rack(rack['id'])
				devices_on_this_rack.each do |device|
					# Some devices don't have a position of their own (i.e. Blade components)
					unless device['position'].nil?
						# Rack numbers are bottom to top, coordinates are top to bottom
						usdown = rack_usize - device['position']
						svgarray.push("<!-- Device Name: #{device['name']} Position: #{device['position']} --\>")
						device_u = get_size_by_device_name(device['name'])
						device_height = u_height * device_u
						# Draw from botton up
						if device_u > 1
							pushedup = device_u * u_height - u_height
							device_location = usdown * u_height - pushedup + y
						else
							device_location = usdown * u_height + y
						end
						svgarray.push("<rect id='1#{device['id']}' height='#{device_height}' width='#{rack_width}' y='#{device_location}' x='#{x}' stroke='#000' stroke-width='1' fill='#96A4A8'/>")
						device_text_y = device_height / 2 + device_location + 5
						svgarray.push("<text id='1#{device['id']}' xml:space='preserve' text-anchor='start' font-family='Helvetica, Arial, sans-serif' font-size='14' y='#{device_text_y}' x='#{text_location}' stroke-width='0' stroke='#000' fill='#000000'>#{device['name']}</text>")
					end
				end
				# Draw the racks next to each other
				x += rack_width + rack_space
			end
		
			svgarray.push("<text id='1' xml:space='preserve' text-anchor='start' font-family='Helvetica, Arial, sans-serif' font-size='10' y='60' x='7.5' stroke-width='0' stroke='#000' fill='#000000'>42</text>")
			svgarray.push("</svg>")
			svgarray.join("\n")
		end
	end

	# Visualize Racks
	# 
	# Extracts Racks and Devices, Transforms the Array
	# calls svgbuild to return the SVG string
	# 
	# Returns: Response, Writes to SVG File
	desc "racks site", "Visualize Racks"
	def racks(site)
		path = 'dcim/racks'
		site_options = {'site_id' => site}
		racks = get(path, site_options)
		svgstring = svgbuild_rack(racks)
		File.open('racks.svg', 'w') { |f| f << svgstring }
	end
end

NetboxClient.start(ARGV)
