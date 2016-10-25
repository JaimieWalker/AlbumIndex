require "uri"
require "net/http"
require "json"
require "open-uri"

class LastFM
	attr_accessor :base_url, :request,:params,:artists,:tracks,:albums
	def initialize(api_key,request)
		@base_url = "http://ws.audioscrobbler.com/2.0/?api_key=#{api_key}&format=json"
		@request = request
		@params = request.params
		if !@params["artist"].nil? && @params["artist"].size > 0
			@artists = searchArtists
		end
		if !@params["song"].nil? && @params["song"].size > 0
			@tracks = searchSongs
		end

		if !@params["album"].nil? && @params["album"].size > 0
			@albums = searchAlbums
		end
		binding.pry
	end
	# Takes either an artist passed in or the artist that was passed in for the request

	def searchArtists(artist = @params["artist"])
		urlMethod = "&method=artist.search"
		artist_url_escaped = "&artist=" + URI.escape(artist)
		api_url = URI.parse(@base_url + urlMethod + artist_url_escaped)
		binding.pry
		response = api_request(api_url)
		# returns json of artists
		return response.body
	end

	def searchSongs(song = @params["song"])
		artist = ""
		autocorrect = '&autocorrect=1';
		urlMethod = "&method=track.search"
		if !@params["artist"].nil? && @params["artist"].size > 0
			urlMethod = "&method=track.getinfo"
			artist = "&artist=" + URI.escape(@params["artist"])
		end
		track_url_escaped = "&track=" + URI.escape(song)
		api_url = URI.parse(@base_url + urlMethod + track_url_escaped + artist + autocorrect)
		binding.pry
		response = api_request(api_url)
		# returns json of tracks/songs
		return response.body
	end

	def searchAlbums(album = @params["album"])
		urlMethod = "&method=album.search"
		artist = ""
		autocorrect = '&autocorrect=1';
		if !@params["artist"].nil? && @params["artist"].size > 0
			urlMethod = "&method=album.getinfo"
			artist = "&artist=" + URI.escape(@params["artist"])
		end
		album_url_escaped = "&album=" + URI.escape(album)
		api_url = URI.parse(@base_url + urlMethod +album_url_escaped + autocorrect + artist)
		binding.pry
		response = api_request(api_url)
		# returns json of albums
		return response.body
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