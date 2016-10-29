require "#{Rails.root}/app/controllers/concerns/LastFM.rb"
class SearchController < ApplicationController
	def index
		render "search/index.html.erb"
	end

	def resource
		lastfm_search = LastFM.new(Rails.application.secrets.LASTFM_KEY,request)
		binding.pry
	end
end
