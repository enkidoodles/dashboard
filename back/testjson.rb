require 'net/http'
require 'json'

# url = 'https://api.spotify.com/v1/search?type=artist&q=tycho'
url = 'http://localhost:8080/job/hello/lastBuild/api/json'




uri = URI(url)

response = Net::HTTP.get(uri)
JSON.parse(response)
