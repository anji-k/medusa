require 'matrix'
class Surface < ActiveRecord::Base
  include HasRecordProperty

  paginates_per 10

  has_many :surface_images, :dependent => :destroy, :order => ("position DESC")
  has_many :not_belongs_to_layer_surface_images, -> { not_belongs_to_layer }, class_name: 'SurfaceImage'
  has_many :wall_surface_images, -> { wall }, class_name: 'SurfaceImage'
  has_many :images, through: :surface_images
  has_many :surface_layers, :dependent => :destroy, :order => ("priority DESC")
  has_many :spots, through: :images
  has_many :direct_spots, class_name: "Spot", foreign_key: :surface_id

  accepts_nested_attributes_for :surface_images

  #after_save :make_map

  validates :name, presence: true, length: { maximum: 255 }, uniqueness: true

  def map_dir
    File.join(Rails.public_path,"system/maps",global_id)
  end

  def publish!
    objs = [self]
    objs.concat(self.surface_images.map(&:image))
    objs.compact!
    objs.each do |obj|
      obj.published = true if obj
      obj.save
    end
  end

  def make_map(opts = {})
    #maxzoom = opts[:maxzoom] || 5
    surface_images.order("position ASC").each_with_index do |surface_image, index|
      options = opts
      options.merge!(:transparent => true) if index > 0
      TileWorker.perform_async(surface_image.id, options)
      #surface_image.make_tiles(opts.merge({:transparent => true})) if index > 0
    end
  end

  def spots
    ss = []
    image = first_image
    surface_images.each do |osurface_image|
      oimage = osurface_image.image
      next unless oimage
      next if oimage.affine_matrix.blank?
      #image_region
      opixels = oimage.spots.map{|spot| [spot.spot_x, spot.spot_y]}
      worlds = oimage.pixel_pairs_on_world(opixels)
      pixels = image.world_pairs_on_pixel(worlds)
      oimage.spots.each_with_index do |spot, idx|
      	spot.attachment_file_id = image.id
        spot.spot_x = pixels[idx][0]
        spot.spot_y = pixels[idx][1]
        spot.world_x = worlds[idx][0]
        spot.world_y = worlds[idx][1]
        ss << spot
      end
    end
    ss
  end

  def specimens
    sps = []
    images.each do |image|
      next unless image
      sps.concat(image.specimens) if image.specimens
    end
    sps.compact.uniq
  end

  def first_image
    surface_image = surface_images.first
    surface_image.image if surface_image
  end

  def center
    return if bounds.blank?
    left, upper, right, bottom = bounds
    x = left + (right - left)/2
    y = bottom + (upper - bottom)/2
    [x, y]
  end

  def width
    return if bounds.blank?
    left, upper, right, bottom = bounds
    right - left
  end

  def height
    return if bounds.blank?
    left, upper, right, bottom = bounds
    upper - bottom
  end

  def length
    return if bounds.blank?
    l = width
    l = height if height > width
    l
  end

  def bounds
    return Array.new(4) { 0 } if globe? || surface_images.blank?
    left,upper,right,bottom = surface_images[0].bounds
    surface_images.each do |s_image|
      image = s_image.image
      next if s_image.bounds.blank?
      l,u,r,b = s_image.bounds
      left = l if l < left
      upper = u if u > upper
      right = r if r > right
      bottom = b if b < bottom
    end
    [left, upper, right, bottom]
  end

  def bbox
    [center[0] - length/2, center[1] + length/2, center[0] + length/2, center[1] - length/2]
  end

  def tilesize
    256
  end

  def ntiles(zoom)
    2**zoom
  end

  def length_per_pix(zoom)
    pix = tilesize * ntiles(zoom)
    length/pix.to_f
  end

  def affine_matrix_for_map
    x = tilesize
    y = tilesize
    left, top, _ = bounds
    len = length
    #puts "len: #{len} left: #{left} top: #{top} x: #{x} y: #{y}"
    return if len == 0
    x_offset = (len - width) / 2
    y_offset = (len - height) / 2
    Matrix[
      [256 / len, 0, (x_offset - left) * 256 / len],
      [0, -256 / len, (y_offset + top) * 256 / len],
      [0, 0, 1]
    ]
  end


  def coords_on_map(world_coords)
    flag_single = true if world_coords[0].is_a?(Float)
    if flag_single
      world_coords = [world_coords]
    end
    n = Matrix.columns(world_coords)
    n = Matrix.rows(n.to_a << Array.new(world_coords.size, 1))
    matrix = affine_matrix_for_map
    nn = matrix * n
    coords = []
    nn.t.to_a.each do |r|
      coords << [r[0],r[1]]
    end

    flag_single ? coords[0] : coords
  end

  def coords_on_world(map_coords)
    flag_single = true if map_coords[0].is_a?(Float)
    if flag_single
      map_coords = [map_coords]
    end
    n = Matrix.columns(map_coords)
    n = Matrix.rows(n.to_a << Array.new(map_coords.size, 1))
    matrix = affine_matrix_for_map.inv
    nn = matrix * n
    coords = []
    nn.t.to_a.each do |r|
      coords << [r[0],r[1]]
    end

    flag_single ? coords[0] : coords
  end



  def tile_ij_at(zooms, x, y)
    flag_single = true if zooms.is_a?(Integer)
    if flag_single
      zooms = [zooms]
    end
    
    left, upper, right, bottom = bbox
    dx = x - left
    dy = upper - y

    ijs = []
    zooms.each do |zoom|
      n = ntiles(zoom)
      lpp = length_per_pix(zoom)

      ii = dx/(lpp * tilesize)
      jj = dy/(lpp * tilesize)

      i = ii.floor
      i = 0 if (i < 0)
      i = n - 1 if i > n - 1
      j = jj.floor
      j = 0 if j < 0
      j = n - 1 if j > (n - 1)
      ijs << [i,j]
    end
    if flag_single 
      ijs = ijs[0]
    end
    ijs
  end

  def tile_i_at(zoom, x)
    n = ntiles(zoom)
    left, upper, right, bottom = bbox
    delta = x - left
    #delta = 0.0 if x - left < 1E-5
    ii = delta/(length_per_pix(zoom) * tilesize)
    i = ii.floor
    i = 0 if (i < 0)
    i = n - 1 if i > n - 1
    i
  end


  def tile_j_at(zoom, y)
    n = ntiles(zoom)
    left, upper, right, bottom = bbox
    delta = upper - y
    jj = delta/(length_per_pix(zoom) * tilesize)
    j = jj.floor
    j = 0 if j < 0
    j = n - 1 if j > (n - 1)
    j
  end

  def tile_at(zoom, xy)
    tile_ij_at(zoom, xy[0],xy[1])
  end

#  def as_json(options = {})
#    super({ methods: [:global_id, :image_ids, :globe, :center, :length, :bounds] }.merge(options))
#  end

  def pml_elements
    if globe?
      places = Place.all
      array = []
      array << places.map(&:specimens)
      array << places.map(&:bibs)
      array = array.flatten.compact.uniq
      array = array.map(&:pml_elements).flatten.compact.uniq
      array
    else
      super
    end
  end

  private

  def make_tile_of_added_image(image)
    return if image.affine_matrix.blank?
    index = surface_images.find_index { |surface_image| surface_image.image_id == image.id }
    return unless index
    TileWorker.perform_async(surface_images[index].id, :transparent => index > 0)
  end
end
