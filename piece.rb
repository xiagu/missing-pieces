class Piece
  
  attr_reader :owner

  def initialize(owner) 
    @owner = owner
  end
  
  def owner_string
    str = 'R' if @owner == :red
    str = 'B' if @owner == :blue
    return str
  end

  def to_json( *args )
  	return {:owner => @owner}.to_json( args )
  end
  
end
