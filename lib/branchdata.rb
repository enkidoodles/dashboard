require 'net/http'
require 'uri'
require 'json'
require 'date'

# String to be appended to the Jenkins URL to obtain the JSON file containing build information
$AccessTree = "api/json?tree=name,healthReport[description,score],jobs[name,healthReport[description,score],color,healthReport[description,score],jobs[name,healthReport[description,score],color,jobs[name,color,lastBuild[timestamp,number,changeSet[items[msg,id,author[fullName]]]]],lastBuild[timestamp,number,changeSet[items[msg,id,author[fullName]]]]]]"

# Class to contain all parsed information of Jenkins job being pertained to by the Jenkins URL

class Branchdata

	def initialize(url, name, disp, msg)
		if url[-1] != '/'
			@branch_url = url + "/" + $AccessTree
		else
			@branch_url = url + $AccessTree
		end
		@branch_name = name
		@display = disp
		@message = msg
		@parsed = nil
		@jobs = nil

		# Get json file
		uri = URI.parse(@branch_url)
		response = Net::HTTP.get(uri)

		# Was there a valid response?
		if response[0] == '{'
			@parsed = JSON.parse(response)
			@jobs = @parsed["jobs"]
		else
			@branch_name = nil
		end

		@day = Date.today.to_time.to_i
		@countPerDay = 0
		@buildsPerDay = Array.new
		@countPerWeek = 0
		@buildsPerWeek = Array.new

		# Get latest Sunday
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

	def getJobCount
		return @parsed["jobs"].size
	end

	def getJobs
		if @parsed["jobs"].nil?
			return 0
		else
			return @parsed["jobs"]
		end
	end

	def name
		return @branch_name
	end

	def display
		return @display
	end

	def msg
		return @message
	end

	def null
		return nil
	end

	# Gets latest hudson.model.FreeStyleBuild of a certain hudson.model.FreeStyleProject
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

	# Get latest job in a collection of jobs or hudson.model.FreeStyleProject
	def getLatestJob(jobs)
		# Initialize lastJob and lastBuildTime
		if jobs.nil?
			return nil
		end
		lastJob = nil
		lastBuildTime = -1
		jobs.each do |job|
			# Get latest build of job
			latestBuild = getLatestBuild(job)
			if !(latestBuild == nil)
				# Get the latest build timestamp of the job and update lastBuildTime and lastJob if needed
				buildTime = latestBuild["timestamp"]
				if lastBuildTime < buildTime
				  	lastBuildTime = buildTime
				  	lastJob = job
				end
			end
		end
		return lastJob
	end

	# Get latest commit from the latest job from a list of jobs
	def getLatestCommit(build)
		latestCommit = build["changeSet"]["items"][-1]
		return latestCommit
	end

	def getSubjobs(job)
		if not job["jobs"].nil?
			subjobs = job["jobs"]
			return subjobs
		else
			return nil
		end
	end

	def getStatus(job)
		if job["_class"] == "com.cloudbees.hudson.plugins.folder.Folder"
			healthReport = job["healthReport"]
			if healthReport.nil? || healthReport == []
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

	def folders
		if @jobs.nil?
			return []
		end
		folderList = []
		@jobs.each do |job|
			if job["_class"] == "com.cloudbees.hudson.plugins.folder.Folder"
				folderList << job
			end
		end
		return folderList
	end

	def projects
		if @jobs.nil?
			return []
		end
		projectList = []
		@jobs.each do |job|
			if job["_class"] == "hudson.model.FreeStyleProject"
				projectList << job
			end
		end
		return projectList
	end

	def reportHealth(type)
		healthReport = @parsed["healthReport"]
		print "looking for "+type+": "
		if healthReport.nil?
			return nil
		end
		value = 0
		healthReport.each do |hr|
			if type == "average" and hr["description"].include? "Average health"
				value = hr["score"].to_i
				break
			elsif type == "worst" and hr["description"].include? "Worst health:"
				value =  hr["description"]
				break
			elsif type == "success" and hr["description"].include? "successful builds"
				value =  hr["description"].split(' ')[4].to_i
				break
			elsif type == "fail" and hr["description"].include? "failed builds"
				value =  hr["description"].split(' ')[4].to_i
				break
			elsif type == "unstable" and hr["description"].include? "unstable builds"
				value =  hr["description"].split(' ')[4].to_i
				break
			elsif type == "builds" and hr["description"].include? "Jobs with builds:"
				value =  hr["description"].split(' ')[3].to_i
				break
			end
		end
		return value
	end

	def reportProjectHealth(project)
		healthReport = project["healthReport"]
		healthReport.each do |hr|
			if hr["description"].include? "Build stability"
				desc = hr["description"]
				desc.slice!(0..16)
				return desc
			end
		end
	end

	def parsed
		return @parsed
	end
	
	def getFolderProps(status)
		statusProps = {}
		if status >= 70
			statusProps = {
				"bgColor" => "bg-primary",
				"icon" => "fa-check",
				"color" => "text-white"
			}
		elsif status < 70 and status >= 0
			statusProps = {
				"bgColor" => "bg-danger",
				"icon" => "fa-times",
				"color" => "text-white"
			}
		else
			statusProps = {
				"bgColor" => "bg-black",
				"icon" => "fa-ban",
				"color" => "text-white"
			}
		end
		return statusProps
	end


	def getProjectProps(job)
		projectProps = {}
		if job["color"] == "blue"
			projectProps = {
				"bgColor" => "bg-success",
				"icon" => "fa-check",
				"color" => "text-white"
			}
		elsif job["color"] == "red"
			projectProps = {
				"bgColor" => "bg-danger",
				"icon" => "fa-times",
				"color" => "text-white"
			}
		elsif job["color"] == "yellow"
			projectProps = {
				"bgColor" => "bg-warning",
				"icon" => "fa-exclamation-triangle",
				"color" => "text-white"
			}
		elsif job["color"] == "grey"
			projectProps = {
				"bgColor" => "bg-info",
				"icon" => "fa-hand-paper-o",
				"color" => "text-white"
			}
		elsif job["color"] == "aborted"
			projectProps = {
				"bgColor" => "bg-black",
				"icon" => "fa-ban",
				"color" => "text-white"
			}
		elsif job["color"] == "notbuilt"
			projectProps = {
				"bgColor" => "bg-black",
				"icon" => "fa-question",
				"color" => "text-white"
			}
		else
			projectProps = {
				"bgColor" => "bg-info",
				"icon" => "fa-ban",
				"color" => "text-white"
			}
		end
		if job["color"].include? "_anime"
			projectProps["icon"] = "fa-spin fa-circle-o-notch"
		end
		return projectProps
	end

	def countBuildsPerDay(jobs)
		jobs.each do |job|
			if not job["lastBuild"].nil?
				timeOfBuild = job["lastBuild"]["timestamp"]*0.001
				if not job["lastBuild"]["changeSet"]["items"].nil?
					if (timeOfBuild > @day)
						@countPerDay += 1
					end
				end
			else
				if not job["jobs"].nil?
					countBuildsPerDay(job["jobs"])
				end
			end
		end
		return @countPerDay
	end

	def countBuildsPerWeek(jobs)
		jobs.each do |job|
			if not job["lastBuild"].nil?
				timeOfBuild = job["lastBuild"]["timestamp"]*0.001
				if not job["lastBuild"]["changeSet"]["items"].nil?
					if (timeOfBuild > @lastSunday)
						@countPerWeek += 1
					end
				end
			else
				if not job["jobs"].nil?
					countBuildsPerWeek(job["jobs"])
				end
			end
		end
		return @countPerWeek
	end

end