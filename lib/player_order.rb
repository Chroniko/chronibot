# Poor man's ring buffer

class PlayerOrder
  def initialize(order)
    @buffer = order
  end

  def advance
    new_order = @buffer[1..-1] << next_player
    self.class.new(new_order)
  end

  def next_player
    @buffer.first
  end
end
