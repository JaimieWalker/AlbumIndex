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
		if !response["error"]
			json_artists = JSON.parse(response.body)
			arr = json_artists["results"]["artistmatches"]["artist"]
			arr.each do |artist|
				create_artist(artist)	
			end	
		end
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
		artist_name_escaped = "&artist=" + URI.escape(artist["name"])
		api_url = URI.parse(@base_url + urlMethod + artist_name_escaped + autocorrect)
		response = api_request(api_url)
		return JSON.parse(response.body)
	end
# Searches all songs that match the name and takes a song that was passed in or from the request
	def searchSongs(song = @params["song"])
		artist = ""
		autocorrect = "&autocorrect=1";
		urlMethod = "&method=track.search"

		# if !@params["artist"].nil? && @params["artist"].size > 0
		# 	urlMethod = "&method=track.getinfo"
		# 	artist = "&artist=" + URI.escape(@params["artist"])
		# end
		track_url_escaped = "&track=" + URI.escape(song)
		api_url = URI.parse(@base_url + urlMethod + track_url_escaped + artist + autocorrect)
		
		response = api_request(api_url)
		json_songs = JSON.parse(response.body)
		if !json_songs["error"]
			song_arr = json_songs["results"]["trackmatches"]["track"]
			create_songs(song_arr)

		# elsif !json_songs["error"] && urlMethod == "&method=track.getinfo"
		# 		song_get_info(json_songs["track"])
		end
		# returns json of tracks/songs
		return response.body
	end

# calls track.get_info to get the data about a song
	def song_get_info(song)
		artist = ""
		autocorrect = "&autocorrect=1";
		urlMethod = "&method=track.search"
		if !@params["artist"].nil? && @params["artist"].size > 0
			urlMethod = "&method=track.getinfo"
			artist = "&artist=" + URI.escape(@params["artist"])
		end
		track_url_escaped = "&track=" + URI.escape(song)
		api_url = URI.parse(@base_url + urlMethod + track_url_escaped + artist + autocorrect)
		

		artist = Artist.find_or_create_by(name: song["artist"]["name"], mbid: song["artist"]["mbid"])
		
		album = Album.find_or_create_by(name: song["album"]["title"],mbid: song["album"]["mbid"], artist_id: artist.id) do |current_album|
			current_album.image_url = song["album"]["image"][2]	
		end
		song = Song.find_or_create_by(name: song["name"], mbid: song["mbid"], artist_id: artist.id, album_id: album.id ) do |current_song| 
			current_song.description = song["wiki"]["content"]
		end
	end

	def searchAlbums(album = @params["album"])
		urlMethod = "&method=album.search"
		artist = ""
		autocorrect = "&autocorrect=1";
		# if !@params["artist"].nil? && @params["artist"].size > 0
		# 	urlMethod = "&method=album.getinfo"
		# 	artist = "&artist=" + URI.escape(@params["artist"])
		# end
		album_url_escaped = "&album=" + URI.escape(album)
		api_url = URI.parse(@base_url + urlMethod +album_url_escaped + autocorrect + artist)
		
		response = api_request(api_url)
		json_albums = JSON.parse(response.body)
		album_arr = json_albums["results"]["albummatches"]["album"]
		create_albums(album_arr)
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

	

	def create_albums(arr)
		# When I create an album, get all of the tracks in the album
		arr.each do |album|
			artist = Artist.find_or_create_by(name: album["artist"])
			album_db = Album.find_or_create_by(name: album["name"]) do |current_album|
				current_album.artist_id = artist.id
				current_album.image_url = album["image"][2]["#text"]
				current_album.mbid = album["mbid"]
			end
			album_get_info(artist,album_db)
			artist.albums << album_db

		end
	end

	def create_songs(arr)
		arr.each do |track|
			artist = Artist.find_or_create_by(name: track["artist"])
			artist.songs << Song.find_or_create_by(name: track["name"],artist_id: artist.id) do |current_track|
				current_track.mbid = track["mbid"]
				current_track.image_url = track["image"][2]["#text"]
			end
		end
	end

	def create_songs_from_album_info(arr,artist,album)
		arr.each do |track|
			if artist.mbid != track["artist"]["mbid"]
				artist = Artist.find_or_create_by(name: track["artist"]["name"],mbid: track["artist"]["mbid"])
			end
			album.songs << Song.find_or_create_by(name: track["name"],artist_id: artist.id, album_id: album.id)				
		end
	end
# Need to finish the get info for each
	def album_get_info(artist,album)
		urlMethod = "&method=album.getinfo"
		artist_name = URI.escape(artist.name)
		autocorrect = "&autocorrect=1";
		artist_escaped = "&artist=#{artist_name}"
		album_url_escaped = "&album=" + URI.escape(album.name)
		api_url = URI.parse(@base_url + urlMethod + album_url_escaped + autocorrect + artist_escaped)
		response = api_request(api_url)
		album_info = JSON.parse(response.body)
		# If there is no error
		if !album_info["error"]
			tracks_in_album = album_info["album"]["tracks"]["track"]
			create_songs_from_album_info(tracks_in_album,artist,album)
		end
		
	end

end