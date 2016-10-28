class CreateSongs < ActiveRecord::Migration[5.0]
  def change
    create_table :songs do |t|
      t.string :name
      t.integer :album_id
      t.string :mbid
      t.integer :artist_id
      t.string :image_url
      t.text :description
      t.timestamps
    end
  end
end
