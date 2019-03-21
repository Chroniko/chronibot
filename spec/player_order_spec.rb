require "player_order"

describe PlayerOrder do
  subject(:order) { described_class.new }

  it "marks the first player to take a turn" do
    expect(
      order.mark("first").to_ary
    ).to eq(
      ["first"]
    )
  end

  it "marks the second player to take a turn" do
    expect(
      order.mark("first").mark("second").to_ary
    ).to eq(
      ["second", "first"]
    )
  end

  it "marks the first repeating player to take a turn" do
    expect(
      order.mark("first").mark("second").mark("third").mark("first").to_ary
    ).to eq(
      ["first", "third", "second"]
    )
  end

  it "marks the second repeating player to take a turn" do
    expect(
      order
        .mark("first").mark("second").mark("third")
        .mark("first").mark("second")
        .to_ary
    ).to eq(
      ["second", "first", "third"]
    )
  end

  it "advances to the next turn" do
    expect(
      order
        .mark("first").mark("second").mark("third")
        .mark("first").mark("second")
        .advance
        .to_ary
    ).to eq(
      ["third", "second", "first"]
    )
  end

  it "reports whose turn it is next", :aggregate_failures do
    # Stat with 3 players
    expect(
      order
      .mark("first").mark("second").mark("third").mark("first")
        .next_player
    ).to eq("second")

    # Continue with 4 players
    expect(
      order
      .mark("first").mark("second").mark("third").mark("fourth").mark("first")
        .next_player
    ).to eq("second")

    # Drop down to 2 players
    expect(
      order
        .mark("first").mark("second").mark("first")
        .next_player
    ).to eq("second")
  end
end
