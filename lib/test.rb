require 'net/http'
require 'uri'
require 'json'

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
	# Initialize lastJob and lastBuildNumber
	lastJob = nil
	lastBuildTime = -1
	jobs.each do |job|
		# Get latest build of job
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

# Get latest commit from the latest job from a list of jobs
def getLatestCommit(build)
	latestCommit = build["changeSet"]["items"][-1]
	return latestCommit
end

uri = URI.parse("http://5g-cimaster-4.eecloud.dynamic.nsn-net.net:8080/job/MASTER_DEV/job/AIRPHONE/api/json?tree=name,jobs[name,jobs[name,color,jobs[name,color,lastBuild[timestamp,number,changeSet[items[msg,id,author[fullName]]]]],lastBuild[timestamp,number,changeSet[items[msg,id,author[fullName]]]]]]")
response = Net::HTTP.get(uri)
parsed = JSON.parse(response)

if parsed["_class"] == "com.cloudbees.hudson.plugins.folder.Folder"
	jenkinsJobs = JSON.parse(response)["jobs"]
	jenkinsJobs.each do |jenks|
		puts jenks["name"]
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
				puts "\t"+subjob["name"].to_s+" -> "+subjob["color"].to_s
			end
		end

		puts ""
	end
else
	puts "not a folder"
end