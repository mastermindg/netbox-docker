#!/usr/bin/env ruby

require 'json'
require 'net/http'
require 'uri'
require 'csv'
require 'thor'

## Script to generate visualizations from the API
#
# Uses Thor to manage input
# 
# Example:
# 
# ruby VIS.rb racks
#

# Visualizations are generated with Read operations only
class NetboxVIS < Thor
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
			results
		else
		  puts "Invalid response #{response.code}"
		end
	end


	# Visualize Racks
	# 
	# Returns: Response, Writes to SVG File
	desc "visualize_racks", "Visualize Racks"
	def visualize_racks
		puts "Visualizing"
	end
end

NetboxVIS.start(ARGV)


