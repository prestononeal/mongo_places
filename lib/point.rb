# A GeoJSON Point
class Point
  attr_accessor :longitude, :latitude, :type

  # Initialize from both a Web and GeoJSON Point hash
  def initialize params
    Rails.logger.debug "Initializing a Point (#{params})"
    @type = params[:type]
    @longitude = @type.nil? ? params[:lng] : params[:coordinates][0]
    @latitude = @type.nil? ? params[:lat] : params[:coordinates][1]
  end

  def to_hash
    # GeoJSON Point format
    {:type=>"Point", :coordinates=>[@longitude, @latitude]}
  end
end
