class Place
  include Mongoid::Document

  attr_accessor :id, :location, :address_components, :formatted_address

  def initialize params
    @id = params[:_id].to_s
    @address_components = params[:address_components].map { |x| AddressComponent.new(x)}
    @formatted_address = params[:formatted_address]
    @location = Point.new(params[:geometry][:geolocation])
  end

  # Get a mongo client to communicate with the database (configured in config/mongoid.yml)
  def self.mongo_client
    Mongoid::Clients.default
  end

  # Convenience method for accessing the "places" collection
  def self.collection
    self.mongo_client['places']
  end

  # Accept a JSON file IO object and load its contents
  def self.load_all file
    Rails.logger.debug "Loading file into db"
    data_stream = file.read
    data_hash = JSON.parse data_stream
    collection.insert_many data_hash
  end
end
