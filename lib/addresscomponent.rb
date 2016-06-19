# An AddressComponent class
class AddressComponent
  attr_reader :long_name, :short_name, :types

  # Initialize from both a Web and GeoJSON Point hash
  def initialize params
    Rails.logger.debug "Initializing an AddressComponent (#{params})"
    @long_name = params[:long_name]
    @short_name = params[:short_name]
    @types = params[:types]
  end

  def to_hash
    # GeoJSON Point format
    {:type=>"Point", :coordinates=>[@longitude, @latitude]}
  end
end
