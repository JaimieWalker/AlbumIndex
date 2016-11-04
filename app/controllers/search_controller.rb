require "#{Rails.root}/app/controllers/concerns/LastFM.rb"
class SearchController < ApplicationController
	def index
		render "search/index.html.erb"
	end

	def resource
		request.params.delete_if {|k,v| v == ""}
		lastfm_search = LastFM.new(Rails.application.secrets.LASTFM_KEY,request)
		songs = lastfm_search.search_results
		render json: songs
	end

	def show
		song = Song.find_by_id(params["id"])
		render json: {"song" => song, 
			           "album" => song.album,
			           "artist" => song.artist,
			       		"track_list" => song.album.songs.distinct
			       	}
	end

	def random
		render json: LastFM.songs_to_json(Song.limit(50).order("RAND()"))
	end

	
end
