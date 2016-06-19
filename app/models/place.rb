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

  # Convenience method for retrieving address_components from the collection
  #  * sort (optional):
  #  * offset (optional): document number to start results
  #  * limit (optional): number of documents to include
  def self.get_address_components(sort=nil, offset=nil, limit=nil)
    aggs = []
    aggs << {:$unwind=>"$address_components"}
    aggs << {:$project=>{:_id=>1, :address_components=>1, :formatted_address=>1, "geometry.geolocation": 1}}
    aggs << {:$sort=>sort} if !sort.nil?
    aggs << {:$skip=>offset} if !offset.nil?
    aggs << {:$limit=>limit} if !limit.nil?
    collection.find().aggregate(aggs)
  end

  # Returns a distinct collection of country names (long_names)
  def self.get_country_names
    aggs = []
    aggs << {:$project=>{"address_components.long_name": 1, "address_components.types": 1}}
    aggs << {:$unwind=>"$address_components"}
    aggs << {:$unwind=>"$address_components.types"}
    aggs << {:$match=>{"address_components.types": "country"}}
    aggs << {:$group=>{:_id=>"$address_components.long_name"}}
    countries = collection.find().aggregate(aggs)
    countries.to_a.map {|c| c[:_id]}
  end

  # Returns the ID of each document in the places collection that has an
  # address_component.short_name of type country and matches the provided param
  def self.find_ids_by_country_code(country_code)
    aggs = []
    aggs << {:$match=>{"address_components.types": "country",
      "address_components.short_name": country_code}}
    aggs << {:$project=>{:_id=>1}}
    ids = collection.find().aggregate(aggs)
    ids.to_a.map {|i| i[:_id].to_s}
  end
end
