require "uri"
require "net/http"
require "json"
require "open-uri"

class LastFM < ApplicationController
	attr_accessor :base_url, :request,:params
	def initialize(api_key,request)
		@base_url = "http://ws.audioscrobbler.com/2.0/?api_key=#{api_key}&format=json"
		@request = request

		@params = request.params
		# Thread.new do
		# 	ActiveRecord::Base.transaction do
		# 		if !@params["artist"].nil? && @params["artist"].size > 0
		# 			 add_artists_to_db(search_artists)
					 
		# 		end
		# 		if !@params["song"].nil? && @params["song"].size > 0
		# 			 add_tracks_to_db(search_songs)
		# 		end

		# 		if !@params["album"].nil? && @params["album"].size > 0
		# 			 add_albums_to_db(search_albums)
		# 		end
		# 	end
		# end
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
			# Thread.new {add_artists_to_db(json_artists)} 
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
		return artist_list.uniq
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
		# Thread.new  {add_tracks_to_db(json_songs)}
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
		return tracks.uniq
	end
	# takes an active record artist, album and a string song name
	def create_song(song,artist,album)
		song_info = get_song_info(song,artist.name)
		if !song_info["error"] && song
			ar_song = Song.find_or_create_by(name: song, artist_id: artist.id, album_id: album.id) do |current_song|
				current_song.mbid = song_info["track"]["mbid"]
					current_song.image_url = album.image_url
				if s = song_info["track"]["wiki"]
					current_song.description = s["content"]	
				end
			end
		end
		album.songs << ar_song if !album.songs.include?(ar_song)
			
		return ar_song
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
		if !json_albums["error"]
			# Thread.new {add_albums_to_db(json_albums)} 
			return json_albums
		else
			return nil
		end
	end
# Takes a last fm list of albums
def add_albums_to_db(albums)
	albums_list = []
	if albums
		arr = albums["results"]["albummatches"]["album"]
		arr.each do |album|
			albums_list << create_album(album["name"],album["artist"])
		end
	end
		# Returns a list of albums
		return albums_list.uniq
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
			sleep(2)
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
					# If we reach this point, that means the track wasn't found in the api
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

	def find_songs_by_artist
		artist = Artist.find_by(name: @params["artist"])
		if artist
			return artist.songs
		else
			urlMethod = "&method=artist.getTopAlbums"
			autocorrect = "&autocorrect=1";
			artist_escaped = "&artist=" + URI.escape(@params["artist"])
			api_url = URI.parse(@base_url + urlMethod  + autocorrect + artist_escaped)
			response = api_request(api_url)
			json = JSON.parse(response.body)
			if !json["error"]
				albums = json["topalbums"]["album"]
				albums.each do |album|
					create_album(album["name"],album["artist"]["name"])
				end
					return artist.songs
			else
				return []
			end
		end
	end
	
	def find_songs_by_album
		songs = []
		like_album = "%#{@params['album']}%"
		albums = Album.where("name LIKE ? ", like_album)
		if albums.size  == 0
			albums = add_albums_to_db(search_albums(@params["album"]))
		end	
		albums = albums.compact
		albums.each do |album|
			songs += album.songs
		end
		return songs
	end

	def search_results
		like_song = "%#{@params['song']}%"
		songs = Song.where("name LIKE ? ", like_song)
		if songs != nil && songs.size == 0 && @params["song"]
			songs = add_tracks_to_db(search_songs(@params["song"]))
		elsif @params["album"]
			songs = find_songs_by_album
		elsif @params["artist"]
			songs = find_songs_by_artist
		end
		results = songs_to_json(songs.to_a.uniq)
		return  results
	end

	def songs_to_json(songs)
		data = []
		songs.each do |song|
			 data << {"song" => song, 
			           "album" => song.album,
			           "artist" => song.artist}
		end
		return data.to_json
	end
end