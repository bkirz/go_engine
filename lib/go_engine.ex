defmodule GoEngine do
  @moduledoc """
  Toy game engine for go/wéiqí/baduk for use learning how the game actually works.
  """

  @type player() :: :black | :white

  @type move() :: {player(), move_action()}
  @type move_action() :: :pass | {:place_stone, coordinate()}
  @type coordinate() :: {pos_integer(), pos_integer()}

  defmodule Board do
    fields = [:size, :stone_locations]
    @enforce_keys fields
    defstruct fields

    @type t() :: %__MODULE__{
            size: pos_integer(),
            stone_locations: %{optional(GoEngine.coordinate()) => GoEngine.player()}
          }

    @stone_chars %{black: "●", white: "○"}

    @spec format(t()) :: String.t()
    def format(%__MODULE__{size: size, stone_locations: stone_locations}) do
      Enum.map(1..size, fn row ->
        1..size
        |> Enum.map(fn col ->
          coord = {row, col}

          case Map.fetch(stone_locations, coord) do
            {:ok, player} -> @stone_chars[player]
            :error -> empty_board_char_for(size, {row, col})
          end
        end)
        |> Kernel.++(["\n"])
        |> Enum.join()
      end)
      |> Enum.join()
    end

    defp empty_board_char_for(_size, {1, 1}), do: "┌"
    defp empty_board_char_for(size, {1, size}), do: "┐"
    defp empty_board_char_for(size, {size, 1}), do: "└"
    defp empty_board_char_for(size, {size, size}), do: "┘"
    defp empty_board_char_for(_size, {1, _}), do: "┬"
    defp empty_board_char_for(_size, {_, 1}), do: "├"
    defp empty_board_char_for(size, {size, _}), do: "┴"
    defp empty_board_char_for(size, {_, size}), do: "┤"
    defp empty_board_char_for(_, _), do: "┼"
  end

  defmodule GameState do
    @type turn_state() ::
            {:active, GoEngine.player()}
            | {:active_after_pass, GoEngine.player()}
            | :complete

    @type t() :: %__MODULE__{
            board: Board.t(),
            turn_state: turn_state(),
            prisoners_captured: %{white: integer(), black: integer()}
          }

    fields = [:board, :turn_state, :prisoners_captured]
    @enforce_keys fields
    defstruct fields
  end

  @spec new_game_state(board_size: integer()) :: GameState.t()
  def new_game_state(board_size: board_size) do
    %GameState{
      board: %Board{
        size: board_size,
        stone_locations: %{}
      },
      turn_state: {:active, :black},
      prisoners_captured: %{white: 0, black: 0}
    }
  end

  @spec play_move(GameState.t(), move()) :: GameState.t()
  @doc """
  Given an existing game state and a move, attempts to apply the move to advance the game state.
  If the move is valid, returns {:valid, advanced_game_state}. Otherwise, returns {:invalid, reason}
  """
  def play_move(game_state, move)
  def play_move(%GameState{board: %Board{size: size}}, {_, {:place_stone, {row, col}}})
      when row > size or col > size or row < 1 or col < 1,
      do: {:invalid, :out_of_bounds}

  def play_move(%GameState{board: %Board{stone_locations: locs}}, {_, {:place_stone, at}})
      when is_map_key(locs, at),
      do: {:invalid, :stone_present}

  def play_move(
        game_state = %GameState{turn_state: {_, active_player}},
        {active_player, {:place_stone, at}}
      ) do
    updated_state =
      game_state
      |> Map.update!(:board, fn board ->
        %{board | stone_locations: Map.put(board.stone_locations, at, active_player)}
      end)
      |> Map.put(:turn_state, {:active, next_player(active_player)})

    {:valid, updated_state}
  end

  def play_move(%GameState{turn_state: {_, _active_player}}, {_inactive_player, _}) do
    {:invalid, :out_of_turn}
  end

  defp next_player(:black), do: :white
  defp next_player(:white), do: :black
end
