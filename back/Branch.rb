require 'net/http'
require 'uri'
require 'json'

$AccessTree = "api/json?tree=name,jobs[name,jobs[name,color,jobs[name,color]]]"

class Branch

	def initialize(url)
		@teams = Array.new
		@branch_url = url + $AccessTree
		uri = URI.parse(@branch_url)
		response = Net::HTTP.get(uri)

		if response[0] == '{'
			parsed = JSON.parse(response)
			@branch_name = parsed["name"];
			
			parsed["jobs"].each do |team_info|
				tmp = Team.new(team_info)
				unless tmp.isInvalid
					@teams.push(tmp)
				end
			end
		else
			@branch_name = nil;
		end
	end	

	def update
		@teams.each do |i|
			i.update
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

	def initialize(team_info)
		@builds = Array.new
		@team_name = team_info["name"];
		
		if team_info["jobs"] != nil
			team_info["jobs"].each do |build_info|
				tmp = Build.new(build_info)
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

	def printTeam
		puts "\t#{@team_name}"
		@builds.each do |i|
			i.printBuild
		end
	end

end

class Build

	def initialize(build_info)
		@build_name = build_info["name"]

		if build_info["color"] != nil
			@color = build_info["color"]
			@num = @den = 0
		else
			@color = "black"
			i = 0
			build_info["jobs"].to_a.each do |k|
				if k["color"] == "blue"
					i += 1
				end
			end
			@num = i
			@den = build_info["jobs"].to_a.size
		end
	end

	def isInvalid
		return @build_name.nil?
	end

	def printBuild
		puts "\t\t#{@build_name} #{@color} #{@num}/#{@den}"
	end
end

