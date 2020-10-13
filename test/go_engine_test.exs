defmodule GoEngineTest do
  use ExUnit.Case
  doctest GoEngine

  test "supports advancing the game state" do
    initial_state = GoEngine.new_game_state(board_size: 5)

    assert %GoEngine.GameState{
             turn_state: {:active, :black},
             board: %GoEngine.Board{stone_locations: %{}, size: 5}
           } = initial_state

    {:valid, turn_1_state} = GoEngine.play_move(initial_state, {:black, {:place_stone, {1, 1}}})

    assert %GoEngine.GameState{
             turn_state: {:active, :white},
             board: %GoEngine.Board{stone_locations: %{{1, 1} => :black}}
           } = turn_1_state

    {:valid, turn_2_state} = GoEngine.play_move(turn_1_state, {:white, {:place_stone, {3, 1}}})
    assert turn_2_state.board.stone_locations == %{{1, 1} => :black, {3, 1} => :white}
  end

  test "formats an empty board" do
    expected_board = """
    ┌┬┬┬┐
    ├┼┼┼┤
    ├┼┼┼┤
    ├┼┼┼┤
    └┴┴┴┘
    """

    formatted_board =
      [board_size: 5]
      |> GoEngine.new_game_state()
      |> Map.fetch!(:board)
      |> GoEngine.Board.format()

    assert expected_board == formatted_board
  end

  test "formats a board with some stones on it" do
    state =
      with state <- GoEngine.new_game_state(board_size: 5),
           {:valid, state} <-
             GoEngine.play_move(state, {:black, {:place_stone, {1, 1}}}),
           {:valid, state} <-
             GoEngine.play_move(state, {:white, {:place_stone, {3, 4}}}),
           {:valid, state} <-
             GoEngine.play_move(state, {:black, {:place_stone, {5, 4}}}),
           do: state

    expected_board = """
    ●┬┬┬┐
    ├┼┼┼┤
    ├┼┼○┤
    ├┼┼┼┤
    └┴┴●┘
    """

    formatted_board =
      state
      |> Map.fetch!(:board)
      |> GoEngine.Board.format()

    assert expected_board == formatted_board
  end

  test "rejects moves out of turn" do
    initial_state = GoEngine.new_game_state(board_size: 5)
    assert {:invalid, :out_of_turn} =
             GoEngine.play_move(initial_state, {:white, {:place_stone, {1, 1}}})
  end

  test "rejects placing stones out of bounds" do
    state = GoEngine.new_game_state(board_size: 5)
    assert {:invalid, :out_of_bounds} = GoEngine.play_move(state, {:black, {:place_stone, {0, 0}}})
    assert {:invalid, :out_of_bounds} = GoEngine.play_move(state, {:black, {:place_stone, {0, 1}}})
    assert {:invalid, :out_of_bounds} = GoEngine.play_move(state, {:black, {:place_stone, {1, 0}}})
    assert {:invalid, :out_of_bounds} = GoEngine.play_move(state, {:black, {:place_stone, {6, 6}}})
    assert {:invalid, :out_of_bounds} = GoEngine.play_move(state, {:black, {:place_stone, {1, 6}}})
    assert {:invalid, :out_of_bounds} = GoEngine.play_move(state, {:black, {:place_stone, {6, 1}}})
  end

  test "rejects placing on existing stones" do
    state = GoEngine.new_game_state(board_size: 5)
    {:valid, state} = GoEngine.play_move(state, {:black, {:place_stone, {1, 1}}})
    assert {:invalid, :stone_present} = GoEngine.play_move(state, {:white, {:place_stone, {1, 1}}})
  end

  # test "rejects suicidal plays"

  # test "removes captured stones"
end
