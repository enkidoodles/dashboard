require 'net/http'
require 'uri'
require 'json'

uri = URI.parse("http://5g-cimaster-4.eecloud.dynamic.nsn-net.net:8080/job/MASTER_DEV/job/AIRPHONE/api/json?tree=name,jobs[name,jobs[name,color,jobs[name,color,lastBuild[timestamp,number,changeSet[items[msg,id,author[fullName]]]]],lastBuild[timestamp,number,changeSet[items[msg,id,author[fullName]]]]]]")
response = Net::HTTP.get(uri)
parsed = JSON.parse(response)

parsed.each do |p|
	print p
	puts ""
	puts ""
end