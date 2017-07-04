require 'json'

response = File.read("json")
s = JSON.parse(response)

s["jobs"].each do |i|
	puts i["name"]
end