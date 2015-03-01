class Player
  attr_accessor :game, :points, :losses, :name

  def initialize(name)
    @game = nil
    @name = name
    @points = Hash.new(0)
    @losses = Hash.new(0)
  end

end
