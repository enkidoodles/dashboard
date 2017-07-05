require 'net/http'
require 'uri'
require 'json'

uri = URI.parse("http://mnling500.apac.nsn-net.net/job/AirPhone_L1emu+legacy.POLLING/api/json")
response = Net::HTTP.get(uri)

s = JSON.parse(response)

print "result = #{s["displayName"]}"

# response.code
# response.body
