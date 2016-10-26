class CreateAlbumArtists < ActiveRecord::Migration[5.0]
  def change
    create_table :album_artists do |t|
      t.references :artist, foreign_key: true  
      t.references :album, foreign_key: true
      t.timestamps
    end
  end
end
