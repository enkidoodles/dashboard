require 'net/http'
require 'uri'
require 'json'

$AccessJob = "api/json?tree=name,jobs[name,color]"
$AccessLastBuild = "lastBuild/api/json?tree=result"

class Branch

	def initialize(url)
		@teams = Array.new
		@branch_url = url
		url_temp = url + $AccessJob
		uri = URI.parse(url_temp)
		response = Net::HTTP.get(uri)
		parsed = JSON.parse(response)
		
		parsed["jobs"].each do |k|
			tmp = Team.new(k["name"], url + "job/" + k["name"] + "/")
			unless tmp.isInvalid
				@teams.push(tmp)
			end
		end
		@branch_name = parsed["name"];
	end	

	def softUpdate
		@teams.each do |i|
			i.update
		end
	end

	def hardUpdate
		@teams.clear
		url_temp = @branch_url + $AccessJob
		uri = URI.parse(url_temp)
		response = Net::HTTP.get(uri)
		parsed = JSON.parse(response)
		
		parsed["jobs"].each do |k|
			tmp = Team.new(k["name"], @branch_url + "job/" + k["name"] + "/")
			unless tmp.isInvalid
				@teams.push(tmp)
			end
		end
	end

	def printBranch
		puts @branch_name
		@teams.each do |i|
			i.printTeam
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
				tmp = Build.new(k["name"], url + "job/" + k["name"] + "/")
				unless tmp.isInvalid
					@builds << tmp
				end
			end
		else
			@team_name = nil;
		end
	end

	def isInvalid
		return @team_name.nil?
	end

	def update
		@builds.each do |i|
			i.update
		end
	end

	def printTeam
		puts "\t#{@team_name}"
		@builds.each do |i|
			i.printBuild
		end
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
			else
				@result = false
			end

		else
			@build_name = nil;
		end
	end

	def isInvalid
		return @build_name.nil?
	end

	def update
		uri = URI.parse(@build_url)
		response = Net::HTTP.get(uri)

		if response[0] == '{'
			parsed = JSON.parse(response)

			if parsed["result"] == nil
				build_name = nil;
			elsif parsed["result"] == "SUCCESS"
				@result = true
			else
				@result = false
			end

		else
			@build_name = nil;
		end
	end

	def printBuild
		puts "\t\t#{@build_name} #{@result ? "true" : "false"}"
	end
end