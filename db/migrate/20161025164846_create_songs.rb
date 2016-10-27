class CreateSongs < ActiveRecord::Migration[5.0]
  def change
    create_table :songs do |t|
      t.string :name
      t.references :album
      t.string :mbid
      t.references :artist
      t.string :image_url
      t.text :description
      t.timestamps
    end
  end
end
