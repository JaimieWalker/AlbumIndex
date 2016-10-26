class Album < ApplicationRecord
	has_many :album_songs
	has_many :songs, through: :album_songs
	belongs_to :artist
end
