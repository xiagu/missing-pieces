require './piece.rb'
require 'json'

class Board

  attr_accessor :pieces

  # A 7x6 board.
  ROWS = 6
  COLS = 7
  
  AXES = [:flat, :pos, :vert, :neg] # horizontal, /, |, \
  INDEX_DIF = {
    :flat => 1,
    :pos => 6,
    :vert => 7,
    :neg => 8
  }
  SLOPES = { :flat => 0, :pos => 1, :vert => nil, :neg => -1 }
    

  # Create the board, populate with the standard starting arrangement.
  def initialize
    clear_board
  end

  def add_piece(index, color)
    p = Piece.new(color)
    @board[index] = p
    @pieces[color].push p
  end

  def clear_board
    @board = [nil]*ROWS*COLS
    @pieces = {:blue => [], :red => []}
    @winning = []
  end

  # Prints the board out. Lowercase letters are normal pieces, capital letters are kinged pieces.
  def print_board
    COLS.times { |col| print "|#{col + 1}" }
    puts "|"

    # There's probably a prettier way to do this involving getting the array 4 at a time
    @board.each_with_index { |p,i| 
      # Print piece value
      if p.nil? then
        str = ' ' # empty squares are spaces
      else
        str = p.owner_string
      end
        
      print "|#{str}"

      # print final bar
      puts "| \t #{((i+1-COLS)..(i)).map { |j| j }.inspect}" if i % COLS == COLS - 1
    }
  end

  def display_board(intermediary)
    flash_on = Time.now.usec > 500000
    @board.each_with_index { |p,i|
      next if p.nil?
      # puts "DISPLAYING #{p}"
      # Skip the ones that are in the 'winning' thing to make them flash.
      intermediary.display_square(row_of(i), 6 - column_of(i), p.owner) unless @winning.include? i and flash_on
      # sleep(0.5/1000.0)
    }
  end

  def to_json( *args )
    return JSON.generate @board
  end

  # Check if the given move created a four-in-a-row
  def game_over?(index)
    return false if index.nil? or @board[index].nil?
    
    player = @board[index].owner
    
    multipliers = (-3..3)
    # AXES = [1,6,7,8] # _ / | \
    AXES.each { |axis|
      consecutive = 0
      win_squares = []
      multipliers.each { |mult| 
        check_sq = mult*INDEX_DIF[axis] + index
        # make sure this is a legal diagonal
        next unless valid_diagonal?(index, check_sq, axis)

        p = piece_at(check_sq)
        if p.nil? or p.owner != player then
          consecutive = 0
          win_squares = []
          next
        else
          win_squares.push check_sq
          consecutive += 1
          if consecutive == 4
            @winning = win_squares
            puts "#{@winning}"
            return player 
          end
        end
      }
    }

    return false
  end

  # Returns the four winning indices, previously set through calling game_over?
  def get_winning_indexes
    return @winning
  end

  def full?
    if @pieces[:red].length + @pieces[:blue].length == @board.length then
      @winning = (0...42)
      return true
    else
      return false
    end
  end

  def execute_move(column, turn)
    return nil unless valid_move?(column)
    
    get_column_indices(column).reverse.each { |r|
      next unless @board[r].nil?
      add_piece(r, turn)
      return r
    }
  end

  # Returns if moving in the given column is allowed. That is, returns
  # if the given column is full or not.
  def valid_move?(column)
    return false if column < 0 or column >= COLS
    return 0 < get_column(column).reduce(0) { |nils,i| 
      if i.nil? then
        nils += 1
      else
        nils
      end
    }
  end

  def out_of_bounds?(index)
    return (index < 0 or (index >= @board.length))
  end

  # make sure that the diagonal is actually in-line (doesn't wrap)
  def valid_diagonal?(a, b, axis)
    return true if a == b
    return false if out_of_bounds?(a) or out_of_bounds?(b)

    # sort if necessary
    if column_of(a) < column_of(b) then
      c = b
      b = a
      a = c
    end

    run = (column_of(b) - column_of(a)).abs
    return axis == :vert if run == 0
      
    # enforce floating point division
    rise = (row_of(b) - row_of(a)).to_f
    # puts "Target slope: #{SLOPES[axis]} \t Our slope: #{rise / run}"
    return SLOPES[axis] == rise / run
  end

  def column_of(index)
    return index % COLS
  end

  # Returns the row of the index. Rows are numbered from top to bottom, starting at zero.
  def row_of(index)
    return index / COLS
  end

  # Returns the given column, top to bottom.
  def get_column(column)
    return get_column_indices(column).map { |r| @board[r] }
  end

  # Returns the given column, top to bottom.
  def get_column_indices(column)
    return (0...ROWS).map { |r| r*COLS + column }
  end
 
  # Returns the given row, left to right.
  def get_row(row)
    return get_row_indices(row).map { |c| @board[c] }
  end

  # Returns the given row, left to right.
  def get_row_indices(row)
    return (0...COLS).map { |c| row*COLS + c }
  end

  def even?(index)
    return row_of(index) % 2 == 0
  end
  
  def odd(index)
    return row_of(index) % 2 != 0
  end

  def northeast(index)
    return index - 6
  end

  def northwest(index)
    return index - 8
  end

  def southeast(index)
    return index + 8
  end

  def southwest(index)
    return index + 6
  end

  def piece_at(index)
    return nil if index < 0 # don't wrap
    return @board[index]
  end

  def self.opponent_of(player)
    player == :red ? :blue : :red
  end

end
