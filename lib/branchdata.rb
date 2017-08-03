require 'net/http'
require 'uri'
require 'json'
require 'date'

# String to be appended to the Jenkins URL to obtain the JSON file containing build information
$AccessTree = "api/json?tree=name,jobs[name,jobs[name,color,jobs[name,color,lastBuild[timestamp,number,changeSet[items[msg,id,author[fullName]]]]],lastBuild[timestamp,number,changeSet[items[msg,id,author[fullName]]]]]]"

# Class to contain all parsed information of Jenkins job being pertained to by the Jenkins URL

class Branchdata

	def initialize(url, name, disp, msg)

		@branch_url = url + $AccessTree
		@branch_name = name
		@display = disp
		@message = msg
		@parsed = nil

		# Get json file
		uri = URI.parse(@branch_url)
		response = Net::HTTP.get(uri)

		# Was there a valid response?
		if response[0] == '{'
			@parsed = JSON.parse(response)
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

	def status(subjobs)
		if subjobs.nil? or subjobs.size == 0
			return -1
		end
		total = 0
		success = 0
		subjobs.each do |sj|
			if not sj.nil?
				if sj["color"] == "blue"
					success += 1
				end
				if not (sj["color"] == "notbuilt" or sj["color"] == "disabled" or sj["color"].nil?)
					total += 1
					if (sj["_class"] == "com.cloudbees.hudson.plugins.folder.Folder")
						if not sj["jobs"].nil?
							folderStatus = status(sj["jobs"])
							if folderStatus >= 0.7
								success += 1
							end
						end
					end
				end
			end
		end
		return (success/(total.to_f))
	end

end