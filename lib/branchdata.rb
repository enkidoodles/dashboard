require 'net/http'
require 'uri'
require 'json'
require 'date'

# String to be appended to the Jenkins URL to obtain the JSON file containing build information
$AccessTree = "api/json?tree=name,healthReport[description,score],jobs[name,healthReport[description,score],color,healthReport[description,score],jobs[name,healthReport[description,score],color,jobs[name,color,lastBuild[timestamp,number,changeSet[items[msg,id,author[fullName]]]]],lastBuild[timestamp,number,changeSet[items[msg,id,author[fullName]]]]]]"

# Class to contain all parsed information of Jenkins job being pertained to by the Jenkins URL

class Branchdata

	def initialize(url, name, disp, msg)

		@branch_url = url + $AccessTree
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
		folderList = Array.new
		@jobs.each do |job|
			if job["_class"] == "com.cloudbees.hudson.plugins.folder.Folder"
				folderList << job
			end
		end
		return folderList
	end

	def projects
		projectList = Array.new
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
		healthReport.each do |hr|
			if hr["description"].include? "Average health" and type == "average"
				return hr["score"].to_i
			elsif hr["description"].include? "Worst health:" and type == "worst"
			 	return hr["description"]
			elsif hr["description"].include? "successful builds" and type == "success"
				return hr["description"].split(' ')[4].to_i
			elsif hr["description"].include? "failed builds" and type == "fail"
			 	return hr["description"].split(' ')[4].to_i
			elsif hr["description"].include? "Jobs with builds:" and type == "builds"
				return hr["description"].split(' ')[3].to_i
			end
		end
	end

	def parsed
		return @parsed
	end
	
	def getStatusProps(status)
		statusProps = {}
		if status >= 0.7
			statusProps = {
				"bgColor" => "bg-primary",
				"icon" => "fa-check",
				"color" => ""
			}
		elsif status < 0.7 and status >= 0
			statusProps = {
				"bgColor" => "bg-danger",
				"icon" => "fa-times"
			}
		else
			statusProps = {
				"bgColor" => "bg-primary",
				"icon" => "fa-ban"
			}
		end
		return statusProps
	end

	def getSubjobStatusProps(jobStatus)
		jobStatusProps = {}
		if subjob["color"] == "blue"
			jobStatusProps = {
				"bgColor" => "bg-success",
				"icon" => "fa-check",
				"color" => "text-white"
			}
		elsif subjob["color"] == "red"
			jobStatusProps = {
				"bgColor" => "bg-danger",
				"icon" => "fa-times",
				"color" => "text-white"
			}
		elsif subjob["color"] == "yellow"
			jobStatusProps = {
				"bgColor" => "bg-warning",
				"icon" => "fa-exclamation-triangle",
				"color" => "text-white"
			}
		elsif subjob["color"] == "grey"
			jobStatusProps = {
				"bgColor" => "bg-info",
				"icon" => "fa-hand-paper-o",
				"color" => "text-white"
			}
		elsif subjob["color"] == "aborted"
			jobStatusProps = {
				"bgColor" => "bg-black",
				"icon" => "fa-ban",
				"color" => "text-white"
			}
		end
		if subjob["color"].include? "_anime"
			jobStatusProps["icon"] = "fa-spin fa-circle-o-notch"
		end
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
		elsif job["color"] == "notbuilt"
			projectProps = {
				"bgColor" => "bg-black",
				"icon" => "fa-ban",
				"color" => "text-white"
			}
		else
		end
		return projectProps
	end
end