require "uri"
require "net/http"
require "json"
require "open-uri"

class LastFM < ApplicationController
	attr_accessor :base_url, :request,:params,:artists,:tracks,:albums
	def initialize(api_key,request)
		@base_url = "http://ws.audioscrobbler.com/2.0/?api_key=#{api_key}&format=json"
		@request = request
		@params = request.params
		
		ActiveRecord::Base.transaction do

				if !@params["artist"].nil? && @params["artist"].size > 0
					@artists = searchArtists
				end

				if !@params["song"].nil? && @params["song"].size > 0
					@tracks = searchSongs
				end

				if !@params["album"].nil? && @params["album"].size > 0
					@albums = searchAlbums
				end
		end
		
	end
	# Searches all songs and takes either an artist passed in or the artist that was passed in from the request, returns a json of artists
	def searchArtists(artist = @params["artist"])
		autocorrect = "&autocorrect=1"
		urlMethod = "&method=artist.search"
		artist_name_escaped = "&artist=" + URI.escape(artist)
		api_url = URI.parse(@base_url + urlMethod + artist_name_escaped + autocorrect)
		response = api_request(api_url)
		searched_artists = []
		if !response["error"]
			json_artists = JSON.parse(response.body)
			arr = json_artists["results"]["artistmatches"]["artist"]
			arr.each do |artist|
				if searched_artists.size < 5
					searched_artists << create_artist(artist["name"])
				else	
					return searched_artists
				end
			end	
		end
		return searched_artists
	end
# Takes an artist name and creates one in the database
	def create_artist(artist)
		artist_info = artist_get_info(artist)
		if !artist_info.nil? && !artist_info["error"]
			artist_info = artist_info["artist"]
			artist = Artist.find_or_create_by(name: artist_info["name"],mbid: artist_info["mbid"]) do |current_artist|
				current_artist.bio = artist_info["bio"]["content"]
				current_artist.image_url = artist_info["image"][2]["#text"];
			end
		end
		return artist
	end
# Just makes an api call to artist.getinfo and returns the JSON parsed result
	def artist_get_info(artist)
		autocorrect = "&autocorrect=1"
		urlMethod = "&method=artist.getinfo"
		artist_name_escaped = "&artist=" + URI.escape(artist)
		api_url = URI.parse(@base_url + urlMethod + artist_name_escaped + autocorrect)
		response = api_request(api_url)
		return JSON.parse(response.body)
	end
# Searches all songs that match the name and takes a song that was passed in or from the request
	def searchSongs(song = @params["song"])
		artist_name = @params["artist"] && @params["artist"].size > 0 ? URI.escape(@params["artist"]) : ""
		autocorrect = "&autocorrect=1";
		urlMethod = "&method=track.search"
		track_url_escaped = "&track=" + URI.escape(song)
		api_url = URI.parse(@base_url + urlMethod + track_url_escaped + autocorrect + "&artist=" + artist_name)
		response = api_request(api_url)
		songs = []
		# Returns a list of songs
		json_songs = JSON.parse(response.body)
		if !json_songs["error"]
			arr = json_songs["results"]["trackmatches"]["track"]
			arr.each do |song|
				if songs.size < 5
					artist = create_artist(song["artist"])
					song_info = song_get_info(song["name"],artist.name)
					if !song_info["error"] && song_info["track"]["album"]
						album_name = song_info["track"]["album"]["title"]
						album = create_album(album_name,artist.name)
						songs << create_song(song["name"],artist,album)
					end
				else
					return songs
				end
			end
		end
		return songs
	end
	# takes an active record artist, album and song name
	def create_song(song,artist,album)
		song_info = song_get_info(song,artist.name)
		if !song_info["error"] && song
			ar_song = Song.find_or_create_by(name: song, artist_id: artist.id, album_id: album.id) do |current_song|
				current_song.mbid = song_info["track"]["mbid"]
				if s = song_info["track"]["wiki"]
					current_song.description = s["content"]	
				end
			end
		end
		return ar_song
	end

# Takes a song name and an artist name
	def song_get_info(song,artist)
		urlMethod = "&method=track.getInfo"
		autocorrect = "&autocorrect=1";
		song_escaped = URI.escape(song)
		artist_escaped = URI.escape(artist)
		api_url = URI.parse(@base_url + urlMethod +"&track=#{song_escaped}"  + autocorrect + "&artist=#{artist_escaped}")
		response = api_request(api_url)
		return JSON.parse(response.body)
	end

	def searchAlbums(album = @params["album"])
		urlMethod = "&method=album.search"
		artist = @params["artist"] && @params["artist"].size > 0 ? URI.escape(@params["artist"]) : ""
		autocorrect = "&autocorrect=1";
		album_url_escaped = "&album=" + URI.escape(album)
		api_url = URI.parse(@base_url + urlMethod + album_url_escaped + autocorrect + artist)
		response = api_request(api_url)
		albums = []
		if !response["error"]
			json_albums = JSON.parse(response.body)
			arr = json_albums["results"]["albummatches"]["album"]
			arr.each do |album|
				if albums.size < 5
			 		albums <<	create_album(album["name"],album["artist"])
			 	else
			 		return albums
				end
			end
		end
		# Returns a list of albums
		return albums
	end
# returns a HTTP response object
	def api_request(api_url)
		http = Net::HTTP.new(api_url.host, api_url.port);
		req = Net::HTTP::Get.new(api_url.request_uri);
		req["User-Agent"] = @request.user_agent
		req["Accept"] = "json"
		begin
			res =  http.request(req)
		rescue Errno::ETIMEDOUT => e
			sleep(3)
			retry
		ensure
			return res		
		end
	end

	
# Takes an album name and artist name
	def create_album(album,artist)
	# returns an album with all its songs
		album_info = album_get_info(album,artist)
		if !album_info["error"]
			ar_artist = create_artist(artist)
			ar_album = Album.find_or_create_by(name: album_info["album"]["name"],artist_id: ar_artist.id) do |current_album|
				current_album.image_url = album_info["album"]["image"][2]["#text"]
				current_album.mbid = album_info["album"]["mbid"]
				if a = album_info["album"]["wiki"]
					current_album.description = a["content"]	
				end
			end
			tracks_in_album = album_info["album"]["tracks"]["track"]
			tracks_in_album.each do |track|
				begin
					ar_album.songs << create_song(track["name"],ar_artist,ar_album)				
				rescue ActiveRecord::AssociationTypeMismatch => e
					next
				end
			end
			ar_artist.albums << ar_album
		end
		return ar_album
	end

# Need to finish the get info for each
	def album_get_info(album,artist)
		urlMethod = "&method=album.getinfo"
		autocorrect = "&autocorrect=1";
		artist_escaped = "&artist=" + URI.escape(artist)
		album_url_escaped = "&album=" + URI.escape(album)
		api_url = URI.parse(@base_url + urlMethod + album_url_escaped + autocorrect + artist_escaped)
		response = api_request(api_url)
		return JSON.parse(response.body)
	end

end