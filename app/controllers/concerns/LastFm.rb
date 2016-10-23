require "uri"
require "net/http"
require "json"
require "open-uri"

class LastFM
	attr_accessor :base_url, :request,:params
	def initialize(api_key,request)
		@base_url = "http://ws.audioscrobbler.com/2.0/?api_key=#{api_key}&format=json&"
		@request = request
		@params = request.params
		if @params["artist"] != ""
			searchArtists
		end
	end

	def searchArtists
		urlMethod = "&method=artist.search"
		artist = '&artist=' + URI.escape(@params["artist"])
		api_url = URI.parse(@base_url + urlMethod + artist)
		response = api_request(api_url)
		# returns json of artists
		binding.pry
		return response.body
	end

	def searchTracks
		
	end

	def searchAlbums
		
	end
# returns a HTTP response object
	def api_request(api_url)
		http = Net::HTTP.new(api_url.host, api_url.port);
		req = Net::HTTP::Get.new(api_url.request_uri);
		req["User-Agent"] = @request.user_agent
		req["Accept"] = "json"
		return  http.request(req)
	end

end