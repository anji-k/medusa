class CreatePlaces < ActiveRecord::Migration
  def change
    create_table :places do |t|
      t.string :name
      t.text   :description
      t.float  :latitude
      t.float  :longitude
      t.float  :elevation
      
      t.timestamps
    end
  end
end
