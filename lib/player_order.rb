class PlayerOrder
  def initialize
    @buffer = []
  end

  def mark(player)
    player_position = @buffer.index(player)
    @buffer = @buffer[0, player_position] if player_position
    @buffer.unshift(player)
    self
  end

  def advance
    player = @buffer.pop
    @buffer.unshift(player)
    self
  end

  def next_player
    @buffer.last
  end

  def to_ary
    @buffer
  end
  alias to_a to_ary
end
