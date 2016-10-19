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
		binding.pry
		newUrl = @base_url + urlMethod + artist
		
	end

	def searchTracks
		
	end

	def searchAlbums
		
	end

end