require 'spec_helper'
require "LastFM"
require "Artist"
require "Album"
require "Song"

describe LastFM do 
	class Request
		attr_accessor :params, :user_agent
		def initialize
			@params = {"artist" => "Michael Jackson", "song" => "thriller","album" => "thriller"}
			@user_agent =  "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/54.0.2840.71 Safari/537.36"
		end
	end

	context "Creates an instance of a LastFM object" do
			it "creates a url with the api_key" do 
				request = Request.new
				api_key = 1234
				lastfm = LastFM.new(api_key,request)
				expect(lastfm). to be_instance_of(LastFM)
			end

			it "has a method to return a base url " do
				request = Request.new
				api_key = 1234
				lastfm = LastFM.new(api_key,request)
				expect(lastfm).to respond_to(:base_url)
			end

			it "has a method to return a base url " do
				request = Request.new
				api_key = 1234
				lastfm = LastFM.new(api_key,request)
				expect(lastfm).to respond_to(:base_url)
			end

			it "has a method to view params" do
				request = Request.new
				api_key = 1234
				lastfm = LastFM.new(api_key,request)
				expect(lastfm).to respond_to(:params)
			end

			it "base url has the api_key in it" do
				request = Request.new
				api_key = 1234
				lastfm = LastFM.new(api_key,request)
				url = lastfm.base_url
				expect(url).to include(api_key.to_s)
				expect(url).to include("http://")
			end

			it "creates an artist object and returns it" do
				request = Request.new
				api_key = Rails.application.secrets.LASTFM_KEY
				lastfm = LastFM.new(api_key,request)
				lastfm.create_artist("Michael Jackson").should be_a(Artist)
			end

			it "creates an album from an album name and artist name" do 
				request = Request.new
				api_key = Rails.application.secrets.LASTFM_KEY
				lastfm = LastFM.new(api_key,request)
				artist = lastfm.create_artist("Michael Jackson")
				lastfm.create_album("Thriller",artist.name).should be_a(Album)
			end

			it "A song cannot be created without an artist" do
				expect(Song.new(name: "something", mbid: "mbid",url: "some_url",image_url: "image_url" )).to_not be_valid
			end

			it "creates a song using a string, Artist, and Album" do
				request = Request.new
				api_key = Rails.application.secrets.LASTFM_KEY
				lastfm = LastFM.new(api_key,request)
				artist = lastfm.create_artist("Michael Jackson")
				album = lastfm.create_album("Thriller",artist.name)
				lastfm.create_song("thriller",artist,album).should be_a(Song)
			end

			it "#search_results returns a json string" do 
				request = Request.new
				api_key = Rails.application.secrets.LASTFM_KEY
				lastfm = LastFM.new(api_key,request)
				lastfm.search_results.should be_a(String)
			end


	end
end