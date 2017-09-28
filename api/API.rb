require 'json'
require 'net/http'
require 'uri'
require 'csv'

## Script to call NetBox API
#
# Arguments passed to this script will call class methods
# 
# Example:
# 
# ruby API.rb dns_combine
#
# Make sure to set this to wherever the server is running:
base = "http://localhost"
fun = ARGV[0]

## Class to call the Netbox API and get various results
# Takes an optional "options" hash which is passed to the API request
# The default options hash returns all results without filtering
class NetboxAPI
	@@options = {'limit' => 0, 'offset' => 0}

	def initialize(base_url, options = @@options)
		@base_url = base_url
		@@options = options
	end

	# Call the API
	# Return: JSON
	def call(path, options = nil)
		options = @@options if options.nil?
		unless options.instance_of?(Hash)
			return nil
		end
		options = URI.encode_www_form(options)
		url = "#{@base_url}/api/#{path}/?#{options}"
		uri = URI.parse(url)
		response = Net::HTTP.get_response(uri)
		if response.code == '200'
		  JSON.parse(response.body)['results']
		else
		  puts "Invalid response #{response.code}"
		end
	end

	## DNS methods
	#
	# Each method returns an array of hosts, ips, service names, and ips


	# Gets all of the Virtual machines hosts, ips and related services
	# This is hacky since we're running 2.2 beta
	# Once PR is merged this can be removed in favor of default method
	# 
	# Optional limit argumument to limit the number of results given
	# 
	# Returns: Array
	def dns_vms(limit = 0)
		array = Array.new
		path = 'virtualization/virtual-machines'
		options = {'status' => 1, 'limit' => limit, 'offset' => 0}
		vms = call(path,options)
		vms.each do |vm|
			hash = Hash.new
			id = vm['id']
			hash['name'] = vm['name']
			# Get IP address by getting the IP ID
			ip_id = vm['primary_ip4']
			unless ip_id.nil?
				ip_options = {'id__in' => ip_id}
				ipam = call("ipam/ip-addresses",ip_options)
				hash['ip'] = ipam[0]['address'].split(/\//).first
			end
			# Cycle thru all services to find mine until this is fixed
			services = call("ipam/services")
			unless services.empty?
				services.each do |service|
					if service['virtual_machine']
						if id == service['virtual_machine']['id']
							ip = service['ipaddresses'][0]['address'].split(/\//).first
							hash['servicename'] = service['name']
							hash['serviceip'] = ip
						end
					end
				end
			end
			array << hash
		end
		array
	end

	# Returns node names, ips, and related service names and ips for use in order
	# to populate DNS
	# 
	# Optional limit argumument to limit the number of results given
	# 
	# Returns: Array
	def dns_physical(limit = 0)
		array = Array.new
		path = 'dcim/devices'
		options = {'status' => 1, 'limit' => limit, 'offset' => 0}
		devices = call(path, options)
		devices.each do |device|
			unless device['primary_ip'].nil?
				hash = Hash.new
				hash['name'] = device['name']
				hash['ip'] = device['primary_ip']['address'].split(/\//).first
				service_options = {'device_id' => device['id']}
				services = call("ipam/services",service_options)
				unless services.empty?
					services.each do |service|
						ip = service['ipaddresses'][0]['address']
						hash['servicename'] = service['name']
						hash['serviceip'] = ip.split(/\//).first
					end
				end
				array << hash
			end
		end
		array
	end

	# Combine Virtual Machines and Hardware Device DNS Information into a single array
	# 
	# Returns: True, Writes to CSV
	def dns_combine
		filename='data.csv'
		# Clean up the old file jic
		File.delete(filename)
		vms = dns_vms
		physical = dns_physical
		array = [*vms,*physical]
		array.each do |d|
			open(filename, 'a+') { |f| f << "#{d['name']},#{d['ip']}\n" }
			if d['servicename']
				open(filename, 'a+') { |f| f << "#{d['servicename']},#{d['serviceip']}\n" }
			end
		end
		# De-duplicate services
		dups = File.readlines(filename)
		unqd = dups.uniq
		unqd = unqd.sort
		File.open(filename, 'w') { |f| f << "name,ip\n" }
		File.open(filename, "a+") do |f|
  		f.puts(unqd)
		end
		true
	end
end

API = NetboxAPI.new(base)
if API.respond_to? fun
	puts API.public_send(fun)
else
	puts "No such method"
end
