require "player_order"

describe PlayerOrder do
  subject(:order) { described_class.new([:a, :b, :c, :d]) }

  it "returns the first player" do
    expect(order.next_player).to eq(:a)
  end

  it "returns the second player" do
    expect(order.advance.next_player).to eq(:b)
  end

  it "returns the third player" do
    expect(order.advance.advance.next_player).to eq(:c)
  end

  it "returns the fourth player" do
    expect(order.advance.advance.advance.next_player).to eq(:d)
  end

  it "returns the first player again" do
    expect(order.advance.advance.advance.advance.next_player).to eq(:a)
  end
end
