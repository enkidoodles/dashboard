require 'net/http'
require 'uri'
require 'json'

$AccessJob = "api/json?tree=jobs[name,color]"
$AccessLastBuild = "lastBuild/api/json?tree=result,timestamp,estimatedDuration"

class Branch

	def initialize(name, url)
		@branch_name = name;
		@teams = Array.new
		@branch_url = url + $AccessJob
		uri = URI.parse(@branch_url)
		response = Net::HTTP.get(uri)
		parsed = JSON.parse(response)
		
		puts name
		parsed["jobs"].each do |k|
			puts k["name"]
			tmp = Team.new(k["name"], url + "job/" + k["name"] + "/")
			unless tmp.isInvalid
				@teams.push(tmp)
			end
		end
	end	
end


class Team

	def initialize(name, url)
		@builds = Array.new
		@team_name = name;
		@team_url = url + $AccessJob
		uri = URI.parse(@team_url)
		response = Net::HTTP.get(uri)
		parsed = JSON.parse(response)
		
		if parsed["jobs"] != nil
			parsed["jobs"].each do |k|
				print "\t#{k["name"]} "
				@builds << Build.new(k["name"], url + "job/" + k["name"] + "/")
			end
		else
			@team_name = nil;
		end
	end

	def isInvalid
		return @team_name.nil?
	end
end

class Build

	def initialize(name, url)
		@build_name = name;
		@build_url = url + $AccessLastBuild
		uri = URI.parse(@build_url)
		response = Net::HTTP.get(uri)

		if response[0] == '{'
			parsed = JSON.parse(response)

			if parsed["result"] == nil
				build_name = nil;
			elsif parsed["result"] == "SUCCESS"
				@result = true
				puts @result ? "true" : false
			else
				@result = false
				puts @result ? "true" : false
			end

		else
			@build_name = nil;
		end
		if @build_name == nil
			puts "n/a"
		end
	end

	def isInvalid
		return @build_name.nil?
	end
end



Airphone = Branch.new("Airphone","http://5g-cimaster-4.eecloud.dynamic.nsn-net.net:8080/job/L1_GATEWAY_632B_DEV/job/AIRPHONE/")