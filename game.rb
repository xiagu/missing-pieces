require 'eventmachine'
require 'wiringpi'
require './board.rb'
require './display.rb'

class Game

  attr_reader :cur_board

  class MyKeyboardHandler < EM::Connection
    include EM::Protocols::LineText2

    def initialize(game)
      @game = game
    end

    def receive_line data
      # puts "I received the following line from the keyboard: #{data}"
      column = data.to_i - 1
      @game.try_move(column, :keyboard)
    end
  end

  def initialize(socket_manager, options = {})
    @socket_manager = socket_manager

    @my_options = { :board_player => true, :web_player => true }
    @my_options.merge!(options)

    unless @my_options[:board_player] and @my_options[:web_player] then
      puts "Opening keyboard input"
      # include KeyboardPlayer
      # Spawn EventMachine keyboard processor
      @keyhandler = EM.open_keyboard(MyKeyboardHandler, self)
      puts "Keyboard input opened: #{@keyhandler}"
    end

    @cur_board = Board.new
    @turn = :red
    @turn_count = 0

    # Record which player is playing from where (:board, :keyboard, :website)
    @players = []

    # Set up displaying the physical board
    @game_over = false
  end

  # Run a Connect Four game. Ask for input and move pieces. Terminates when the game ends.
  # What do you do if the game never ends? (timeout)
  def conduct
    # last_move = nil
    # winner = nil
    # until winner = (@cur_board.game_over? last_move) do
    #   print_state

      # Handle different move-getting methods depending on turns
      # Actually mostly just handle board stuff

      # Actually both of them can just keep hitting try_move until it validates as being the right turn

      # last_move = move_piece
      
      # @turn = Board::opponent_of @turn
      # @turn_count += 1
    # end

    # until @game_over do
    #   move_piece
    # end

    # end_game
  end

  def print_state
    puts "========================"
    print "Turn #{@turn_count}\t Player: #{@turn}\n" 
    @cur_board.print_board
  end

  def try_move(column, source)
    return false if @game_over
    # First check move validity, because we don't want to assign going first based on inputting an invalid move
    if @cur_board.valid_move?(column) then

      if @turn_count == 0 then
        @players[@turn_count] = source
      elsif @turn_count == 1
        # Don't let the same player move twice in a row
        # Unless both players are the keyboard
        return false if @players[0] == source and ((@my_options[:board_player] or @my_options[:web_player]) != false)
        @players[@turn_count] = source
      else
        # Only proceed if this is the correct player for this turn
        return false unless @players[@turn_count % 2] == source
      end

      puts "Placing a #{@turn} piece in column #{column}."
      index = @cur_board.execute_move(column, @turn)

      move_made(index, source)

      return true
    else
      puts "Column #{column+1} is full."
      return false
    end
  end

  def move_made(index, source)
    winner = (@cur_board.game_over? index)
    end_game(winner) if winner
    
    end_game(:draw) if @cur_board.full?

    print_state

    @turn = Board::opponent_of @turn
    @turn_count += 1

    if @my_options[:web_player] then
      @socket_manager.send_state(@cur_board, @players[(@turn_count-1) % 2])
    end
  end

  def end_game(winner)
    print_state
    case winner
    when :quit
      puts "Web player quit."
    when :draw
      puts "The game is a draw."
    when :red
    when :blue
      puts "#{winner.to_s.capitalize} wins!"
    end


    if defined? @keyhandler then
      puts "Disconnecting keyhandler"
      @keyhandler.close_connection 
    end
    # if defined? @board_input_thread and @board_input_thread.alive? then
    #   puts "Killing input thread: #{@board_input_thread.status}"
    #   @board_input_thread.join 0.5
    #   puts "Input thread killed"
    # end
    # if @display_thread.alive? then
    #   puts "Killing display thread"
    #   @display_thread.join 0.5
    #   puts "Display thread killed"
    # end
    @socket_manager.send_state(@cur_board, :anyone) if @my_options[:web_player]

    temp = Thread.new {
      sleep(5)

      @game_over = true
      @cur_board.clear_board
      @socket_manager.send_state(@cur_board, :anyone) if @my_options[:web_player]
      @socket_manager.game_finished
    }
  end

  def game_over?
    return @game_over
  end

end