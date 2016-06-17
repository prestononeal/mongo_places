class Place
  include Mongoid::Document

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
