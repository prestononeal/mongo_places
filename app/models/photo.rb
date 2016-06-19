class Photo
  include Mongoid::Document

  attr_accessor :id, :location
  attr_writer :contents

  def initialize(params=nil)
    return if params.nil?
    @id = params[:_id].to_s
    if !params[:metadata].nil?
      if !params[:metadata][:location].nil?
        @location = Point.new(params[:metadata][:location])
      end
      if !params[:metadata][:place].nil?
        @place = params[:metadata][:place]
      end
    else
      @location = nil
      @place = nil
    end
  end

  # Get a mongo client to communicate with the database (configured in config/mongoid.yml)
  def self.mongo_client
    Mongoid::Clients.default
  end

  # Returns true if the instance has been created in GridFS
  def persisted?
    return !@id.nil?
  end

  # Saves this Photo instance into GridFS
  def save
    if self.persisted?
      # Just update the metadata
      ph = self.class.mongo_client.database.fs.find({:_id=>BSON::ObjectId.from_string(@id)})
      ph.update_one(
        {:metadata=>
          {:location=>@location.to_hash, :place=>@place}
        }) if ph.count == 1
      return
    end

    # Get the GPS info from the photo metadata
    gps = EXIFR::JPEG.new(@contents).gps
    @contents.rewind  # Reset the read cursor

    # Store the latitude/longitude information in a Point object
    @location = Point.new(:lng=>gps.longitude, :lat=>gps.latitude)

    # Store meta data about the file
    description = {}
    description[:content_type] = "image/jpeg"
    description[:metadata] = {}
    description[:metadata][:location] = @location.to_hash
    description[:metadata][:place] = @place

    # Save the file
    grid_file = Mongo::Grid::File.new(@contents.read, description)
    id = self.class.mongo_client.database.fs.insert_one(grid_file)
    @id = id.to_s
    @id
  end

  # Return an instance of all pictures as Photo instances
  def self.all(offset=nil, limit=nil)
    phs = mongo_client.database.fs.find()
    phs = phs.skip(offset) if !offset.nil?
    phs = phs.limit(limit) if !limit.nil?
    phs.map { |ph| Photo.new(ph) }
  end

  # Finds a photo in the DB by ID and returns an initialized Photo object for it
  def self.find(id)
    id = BSON::ObjectId.from_string(id) if id.is_a? String
    ph = mongo_client.database.fs.find({:_id=>BSON::ObjectId.from_string(id)})
    Photo.new(ph.first) unless ph.count == 0
  end

  # Accepts a BSON::ObjectId of a Place and returns a collection view of photo
  # documents that have the foreign key reference
  def self.find_photos_for_place(place_id)
    place_id = BSON::ObjectId.from_string(place_id) if place_id.is_a? String
    mongo_client.database.fs.find({"metadata.place": place_id})
  end

  # Returns the data contents of a file
  def contents
    f = self.class.mongo_client.database.fs.find_one({:_id=>BSON::ObjectId.from_string(@id)})
    if f
      buffer = ""
      f.chunks.reduce([]) do |x, chunk|
        buffer << chunk.data.data
      end
      return buffer
    end
  end

  # Destroys the photo associated with this Photo's id
  def destroy
    self.class.mongo_client.database.fs.find(:_id=>BSON::ObjectId.from_string(@id)).delete_one
  end

  # Find the nearest place to this Photo
  def find_nearest_place_id(max_distance)
    near = Place.near(@location, max_distance)
    near = near.limit(1)
    near.projection({:_id=>1}).first[:_id]
  end

  # Custom getter for place attribute
  def place
    Place.find(@place) if !@place.nil?
  end

  # Custom setter for place attribute
  def place=(value)
    case value
    when String
      @place = BSON::ObjectId.from_string(value)
    when BSON::ObjectId
      @place = value
    when Place
      @place = BSON::ObjectId.from_string(value.id)
    else
      @place = nil
    end
  end
end
