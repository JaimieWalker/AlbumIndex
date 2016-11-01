class CreateAlbums < ActiveRecord::Migration[5.0]
  def change
    create_table :albums do |t|
      t.string :name
      t.references :artist_id
      t.string :mbid
      t.string :image_url
      t.text :description
      t.timestamps
    end
  end
end
