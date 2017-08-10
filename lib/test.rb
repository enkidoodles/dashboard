require 'net/http'
require 'uri'
require 'json'
require 'date'

$AccessTree = "api/json?tree=name,healthReport[description,score],jobs[name,healthReport[description,score],color,healthReport[description,score],jobs[name,healthReport[description,score],color,jobs[name,color,lastBuild[timestamp,number,changeSet[items[msg,id,author[fullName]]]]],lastBuild[timestamp,number,changeSet[items[msg,id,author[fullName]]]]]]"

class Brench

	def initialize(url)
		
		@branch_url = url + $AccessTree
		@parsed = nil
		uri = URI.parse(@branch_url)
		response = Net::HTTP.get(uri)
		if response[0] == '{'
			@parsed = JSON.parse(response)
			@jobs = @parsed["jobs"]
		else
			@branch_name = nil
		end
		@day = Date.today.to_time.to_i
		@count = 0
		@commits = Array.new

		dayInWord = Time.now.to_datetime.strftime("%a")
		dayOffset = 0
		if dayInWord == "Sun"
			dayOffset = 0
		elsif dayInWord == "Mon"
			dayOffset = 1
		elsif dayInWord == "Tue"
			dayOffset = 2
		elsif dayInWord == "Wed"
			dayOffset = 3
		elsif dayInWord == "Thu"
			dayOffset = 4
		elsif dayInWord == "Fri"
			dayOffset = 5
		else
			dayOffset = 6
		end
		@lastSunday = (Date.today - dayOffset).to_time.to_i
	end

	def getLatestBuild(job)
		if job.nil?
			return nil
		end
		if job["_class"] == "com.cloudbees.hudson.plugins.folder.Folder"
			# The job has no last build info
			if job["jobs"].nil?
				# The passed job has no latest build or has not been built yet
				return nil
			else
				# Recursive strategy if passed job has subjobs
				return getLatestBuild(getLatestJob(job["jobs"]))
			end
		elsif job["_class"] == "hudson.model.FreeStyleProject"
			return job["lastBuild"]
		else
			return nil
		end
	end

	def getLatestJob(jobs)
		lastJob = nil
		lastBuildTime = -1
		jobs.each do |job|
			latestBuild = getLatestBuild(job)
			if !(latestBuild == nil)
				# Get the latest build number of the job and update lastBuildNumber and lastJob if needed
				buildTime = latestBuild["timestamp"]
				if lastBuildTime < buildTime
				  	lastBuildTime = buildTime
				  	lastJob = job
				end
			end
		end
		return lastJob
	end

	def getLatestCommit(build)
		latestCommit = build["changeSet"]["items"][-1]
		return latestCommit
	end

	def getStatus(job)
		if job["_class"] == "com.cloudbees.hudson.plugins.folder.Folder"
			healthReport = job["healthReport"]
			if healthReport.nil?
				return -1
			end
			healthReport.each do |hr|
				if hr["description"][0..17] == "Average health of "
					if not hr["score"].nil?
						return hr["score"]
					else
						return -1
					end
				end
			end
		elsif job["_class"] == "hudson.model.FreeStyleProject"
			if job["color"] == "notbuilt"
				return -1
			else
				if job["color"] == "blue"
					return "success"
				elsif job["color"] == "red"
					return "fail"
				elsif job["color"] == "notbuilt"
					return "notbuilt"
				else
					return -1
				end
			end
		else
			return -1
		end
	end

	def printHealthSummary
		@jobs.each do |j|
			puts "\t"+j["name"].to_s+" -> "+getStatus(j).to_s
		end
	end

	def parsed
		return @parsed
	end 

	def printHealthReport
		healthReport = @parsed["healthReport"]
		puts healthReport
		if healthReport.nil?
			puts 
		end
		healthReport.each do |hr|
			if hr["description"][0..17] == "Average health of "
				if not hr["score"].nil?
					puts "Average health: "+hr["score"].to_s
				end
			elsif hr["description"][0..12] == "Worst health:"
				puts hr["description"]
			end
		end
		printHealthSummary
		puts ""
	end

	def print

		puts @parsed["name"]
		puts ""

		printHealthReport
		puts ""

		if @parsed["_class"] == "com.cloudbees.hudson.plugins.folder.Folder"
			jenkinsJobs = @parsed["jobs"]
			jenkinsJobs.each do |jenks|
				puts jenks["name"].to_s+" -> "+getStatus(jenks).to_s
				lb = getLatestBuild(jenks)
				if lb.nil?
					puts "not built"
				else
					puts "latest build: "+lb["number"].to_s
					lc = getLatestCommit(lb)
					if lc.nil?
						puts "empty changeset"
					else
						puts "last commit: "+lc.to_s
					end
				end
				if not jenks["jobs"].nil?
					sj = jenks["jobs"]
					sj.each do |subjob|
						puts "\t"+subjob["name"].to_s+" -> "+getStatus(subjob).to_s
					end
				end
				puts ""
			end
		else
			puts "not a folder"
		end
	end

	def countCommits(jobs)
		jobs.each do |job|
			if not job["lastBuild"].nil?
				timeOfBuild = job["lastBuild"]["timestamp"]*0.001
				if not job["lastBuild"]["changeSet"]["items"].nil?
					if (timeOfBuild > @day)
						@count += 1
					end
				end
			else
				if not job["jobs"].nil?
					countCommits(job["jobs"])
				end
			end
		end
		return @count
	end
end

branch = Brench.new("http://5g-cimaster-4.eecloud.dynamic.nsn-net.net:8080/job/MASTER_DEV/job/AIRPHONE/")
# puts branch.countCommits(branch.parsed["jobs"])