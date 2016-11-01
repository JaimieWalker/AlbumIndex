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
		case 
		when p_hash["artist"] && p_hash["song"]
			album = lastfm_search.find_by_artist_song(p_hash["artist"],p_hash["song"])
		when p_hash["album"] && p_hash["song"]
			song = lastfm_search.find_by_song_album(p_hash["song"],p_hash["album"])
		when p_hash["artist"] && p_hash["album"]
			album = lastfm_search.create_album(p_hash["album"],p_hash["artist"])
		end	
	end

	
end
