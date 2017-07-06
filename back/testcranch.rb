require 'net/http'
require 'uri'
require 'json'

$AccessTree = "api/json?tree=name,jobs[name,jobs[name,color,jobs[name,color,builds[number,changeSet[items[author[fullName]]]]],builds[number,changeSet[items[author[fullName]]]]]]"
class Cranch

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

	def getTeams
		return @teams
	end

	def name
		return @branch_name
	end
end


class Team

	def initialize(team_info)
		@builds = Array.new
		@team_name = team_info["name"];
		@ref_number = 0
		commits = Array.new
		
		if team_info["jobs"] != nil
			team_info["jobs"].each do |build_info|
				tmp = Build.new(build_info)
				unless tmp.isInvalid
					@builds << tmp
				end

				z = nil
				if build_info["jobs"] != nil
					z = build_info["jobs"]
					z.each do |x|
						if x["builds"] != nil
							x["builds"].each do |y|
								@ref_number = @ref_number > y["number"] ? @ref_number : y["number"]
								if y["changeSet"] != nil
									a = y["changeSet"]
									if a["items"] != nil
										b = a["items"]
										if b.to_a[-1] != nil
											if b[-1]["author"] != nil
												c = b[-1]["author"]
												if c["fullName"] != nil
													commits << [y["number"], c["fullName"]]
													break
												end
											end
										end
									end
								end
							end
						end
					end
				else
					z = build_info

					if z["builds"] != nil
						z["builds"].each do |y|
							@ref_number = @ref_number > y["number"] ? @ref_number : y["number"]
							if y["changeSet"] != nil
								a = y["changeSet"]
								if a["items"] != nil
									b = a["items"]
									if b.to_a[-1] != nil
										if b[-1]["author"] != nil
											c = b[-1]["author"]
											if c["fullName"] != nil
												commits << [y["number"], c["fullName"]]
												break
											end
										end
									end
								end
							end
						end
					end
				end
				
			end
			@lastcommit = commits.max[1]
		else
			@team_name = nil;
		end
	end

	def isInvalid
		return @team_name.nil?
	end

	def printTeam
		puts "\t#{@team_name} #{@ref_number} #{@lastcommit}"
		@builds.each do |i|
			i.printBuild
		end
	end

	def getBuilds
		return @builds
	end

	def name
		return @team_name
	end
end

class Build

	def initialize(build_info)
		@build_name = build_info["name"]

		if build_info["color"] != nil
			@color = build_info["color"]
			if @color ==  "blue"
				@num = 1;
			else
				@num = 0;
			end
			@den = 1;
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
		return @build_name.nil? || @color == "notbuilt"
	end

	def printBuild
		puts "\t\t#{@build_name} #{@color} #{@num}/#{@den}"
	end

	def getInfo
		return [@build_name, @color, @num, @den]
	end
end

Airphone = Cranch.new("http://5g-cimaster-4.eecloud.dynamic.nsn-net.net:8080/job/5G17_PROD/job/AIRPHONE/")
Airphone.printBranch