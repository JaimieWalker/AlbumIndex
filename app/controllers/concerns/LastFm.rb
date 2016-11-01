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
	end

	# Searches all songs and takes either an artist passed in or the artist that was passed in from the request, returns a json of artists
	def search_artists(artist = @params["artist"])
		autocorrect = "&autocorrect=1"
		urlMethod = "&method=artist.search"
		artist_name_escaped = "&artist=" + URI.escape(artist)
		api_url = URI.parse(@base_url + urlMethod + artist_name_escaped + autocorrect)
		response = api_request(api_url)
		json_artists = JSON.parse(response.body)
		if !json_artists["error"]
			Thread.new do 
				add_artists_to_db(json_artists)
			end
			return json_artists
		else
			return nil
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
	artist_name_escaped = "&artist=" + URI.escape(artist)
	api_url = URI.parse(@base_url + urlMethod + artist_name_escaped + autocorrect)
	response = api_request(api_url)
	return JSON.parse(response.body)
end

	# Takes a last fm list of artists
	def add_artists_to_db(artists)
		artist_list = []
		if artists
			arr = artists["results"]["artistmatches"]["artist"]
			arr.each do |artist|
				if artists.size 
					artist_list << create_artist(artist["name"])
				else	
					return artists
				end
			end	
		end
		return artist_list
	end

# Searches all songs that match the name and takes a song that was passed in or from the request
def search_songs(song = @params["song"])
	artist_name = @params["artist"] && @params["artist"].size > 0 ? URI.escape(@params["artist"]) : ""
	autocorrect = "&autocorrect=1";
	urlMethod = "&method=track.search"
	track_url_escaped = "&track=" + URI.escape(song)
	api_url = URI.parse(@base_url + urlMethod + track_url_escaped + autocorrect + "&artist=" + artist_name)
	response = api_request(api_url)
	json_songs = JSON.parse(response.body)
	if (!json_songs["error"])
		Thread.new do 
			add_tracks_to_db(json_songs)
		end
		return json_songs
	else 
		return nil
	end
end

# Takes a last fm list of songs
def add_tracks_to_db(songs)
		# Returns a list of songs
		tracks = []
		if songs
			arr = songs["results"]["trackmatches"]["track"]
			arr.each do |song|
				artist = create_artist(song["artist"])
				song_info = get_song_info(song["name"],artist.name)
				if !song_info["error"] && song_info["track"]["album"]
					album_name = song_info["track"]["album"]["title"]
					album = create_album(album_name,artist.name)
					tracks << create_song(song["name"],artist,album)
				end
			end
		end
		return tracks
	end
	# takes an active record artist, album and song name
	def create_song(song,artist,album)
		song_info = get_song_info(song,artist.name)
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
	
	def find_by_artist_song(song_name,album_name)
	   	song_info = get_song_info(song_name,album_name)
	    album = create_album(song_info["track"]["album"]["title"],song_info["track"]["artist"]["name"])
	end
	
	def find_by_song_album(song_name,album_name)
		tracks = search_songs(song_name)
		track_list = tracks["results"]["trackmatches"]["track"]
		track_list.each do |track|
			song_name = get_correct_song_name(song_name,track["artist"])
			song_name = song_name["corrections"]["correction"]["track"]["name"]
			song_info = get_song_info(track["name"],track["artist"])
			album = create_album(song_info["track"]["album"]["title"],song_info["track"]["album"]["artist"])
			song = Song.find_by(name: song_name)
			return song if song.album == album
			end
		return nil
	end

	def get_correct_song_name(song,artist)
		urlMethod = "&method=track.getCorrection"
		autocorrect = "&autocorrect=1";
		song_escaped = URI.escape(song)
		artist_escaped = URI.escape(artist)
		api_url = URI.parse(@base_url + urlMethod +"&track=#{song_escaped}"  + autocorrect + "&artist=#{artist_escaped}")
		response = api_request(api_url)
		return JSON.parse(response.body)
	end

# Takes a song name and an artist name
def get_song_info(song,artist)
	urlMethod = "&method=track.getInfo"
	autocorrect = "&autocorrect=1";
	song_escaped = URI.escape(song)
	artist_escaped = URI.escape(artist)
	api_url = URI.parse(@base_url + urlMethod +"&track=#{song_escaped}"  + autocorrect + "&artist=#{artist_escaped}")
	response = api_request(api_url)
	return JSON.parse(response.body)
end

def search_albums(album = @params["album"],artist = @params["artist"])
	urlMethod = "&method=album.search"
	artist = artist && artist.size > 0 ? URI.escape(artist) : ""
	autocorrect = "&autocorrect=1";
	album_url_escaped = "&album=" + URI.escape(album)
	api_url = URI.parse(@base_url + urlMethod + album_url_escaped + autocorrect + artist)
	response = api_request(api_url)
	json_albums = JSON.parse(response.body)
	if json_albums["error"]
		Thread.new {add_albums_to_db(json_albums)} 
		return json_albums
	else
		return nil
	end
end
# Takes a last fm list of albums
def add_albums_to_db(albums)
	albums_list = []
	if albums
		arr = json_albums["results"]["albummatches"]["album"]
		arr.each do |album|
			if albums.size 
				albums_list << create_album(album["name"],album["artist"])
			else
				return albums
			end
		end
	end
		# Returns a list of albums
		return albums_list
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

# takes album name and artist name
def create_album(album,artist)
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
				song = create_song(track["name"],ar_artist,ar_album)
				!ar_album.songs.include?(song) ? ar_album.songs << song : next				
			rescue ActiveRecord::AssociationTypeMismatch => e
				next
			end
		end
		ar_artist.albums << ar_album
	end
	return ar_album
end

# Takes album name and artist name
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