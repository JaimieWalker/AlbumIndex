require "#{Rails.root}/app/controllers/concerns/LastFM.rb"
class SearchController < ApplicationController
	def index
		render "search/index.html.erb"
	end

	def resource
		p_hash = params.to_unsafe_hash
		p_hash.delete_if do |k,v|
			v == ""
		end
		lastfm_search = LastFM.new(Rails.application.secrets.LASTFM_KEY,request)
			binding.pry
		case #For each case, I must implement a check database first method
		when p_hash["artist"] && p_hash["song"] && p_hash["album"]
			artist = lastfm_search.create_artist(p_hash["artist"])
			album = lastfm_search.create_album(p_hash["album"],artist.name)
		when p_hash["artist"] && p_hash["song"]
			album = lastfm_search.find_by_artist_song(p_hash["artist"],p_hash["song"])
		when p_hash["album"] && p_hash["song"]
			song = lastfm_search.find_by_song_album(p_hash["song"],p_hash["album"])
		when p_hash["artist"] && p_hash["album"]
			album = lastfm_search.create_album(p_hash["album"],p_hash["artist"])
		when p_hash["artist"]
			artists = lastfm_search.search_artists(p_hash["artist"])
			result = lastfm_search.add_artists_to_db(artists)
			binding.pry
		when p_hash["song"]
			songs = lastfm_search.search_songs(p_hash["song"])
			result = lastfm_search.add_tracks_to_db(songs)
		when p_hash["album"]
			albums = lastfm_search.search_albums(p_hash["album"])
			result = lastfm_search.add_albums_to_db(albums)
		end	
	end

	
end
