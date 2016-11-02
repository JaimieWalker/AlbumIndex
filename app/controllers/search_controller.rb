require "#{Rails.root}/app/controllers/concerns/LastFM.rb"
class SearchController < ApplicationController
	def index
		render "search/index.html.erb"
	end

	def resource
		request.params.delete_if {|k,v| v == ""}
		lastfm_search = LastFM.new(Rails.application.secrets.LASTFM_KEY,request)
		songs = lastfm_search.search_results
	end

	
end
