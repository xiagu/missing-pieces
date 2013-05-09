require 'em-websocket'
require 'json'
require './game.rb'

class SocketManager

	attr_reader :player, :observers

	def initialize
		@player = nil
		@observers = []
		@game = nil
		@last_board = nil
		@last_player = nil

		run
	end	

	# Sends the state of the game we have to all our clients.
	def send_state(board, prev_player)
		@last_player = prev_player
		return false if @player.nil?

		puts "Sending state to #{player}: #{board} and #{prev_player}"

		send_state_to(@player, board, prev_player != :website, false)
		@observers.each { |o|
			send_state_to(o, board, false, true)
		}
	end	

	def send_state_to(ws, board, turn, observing)
		ws.send({:board => board, :your_turn => turn, :observing => observing }.to_json)
	end

	def game_finished
		if defined? @display then
			puts "Clearing display"
			@display.clear_board 
		end
		@last_player = :anyone
	end

	private
	def run
		# Start threads
		start_display_thread
		start_board_input_thread

		# Make child threads abort when they crash
    	Thread::abort_on_exception=true

		EM.run {
			EM::WebSocket.run(:host => "0.0.0.0", :port => 3000) do |ws|
				ws.onopen { |handshake| 
					# Add to list of clients
					if @player.nil? then 
						puts "Player connected: #{ws}"
						@player = ws
						puts "Current last_player: #{@last_player}"
						send_state_to(ws, board_state, @last_player != :website, false)

						# 5 minute timeout
						# ws.comm_inactivity_timeout = 300
					else
						puts "Observer connected: #{ws}"
						@observers.push ws
						send_state_to(ws, board_state, false, true)

						# 15 minute timeout
						# ws.comm_inactivity_timeout = 900
					end
				}

				ws.onclose { 
					puts "Connection closed by #{ws}"
					# Remove from list of connected clients
					if @player == ws then
						@player = @observers.shift
						# @player.comm_inactivity_timeout = 300 unless @player.nil?
					else
						@observers.delete ws
					end

					puts "Player #{@player} and observers #{@observers}"
					send_state(@last_board, @last_player)
				}

				ws.onmessage { |message| 
					msg = JSON.parse(message)
					puts "Parsed JSON: #{msg}"

					# Don't do anything if it's not from our main player
					if @player == ws and msg['type'] == 'new_move' then
						# @game = Game.new(self, { :board_player => false }) if @game.game_over?
						verify_game_exists
						@game.try_move(msg['column'].to_i, :website)
					end
				}
			end

			puts "Server running"
		}
	end

	def start_display_thread
		@display = BoardIntermediary.new
		@display_thread = Thread.new {
			@display.clear_board
		  	puts "Display thread started"

		  	while(true) do 
				# Can edit code in here to do fancy stuff like flashing the winning line, or flashing the whole board in case of a draw
				unless @game.nil? or @game.cur_board.nil? then
					unless @game.game_over? then
						@game.cur_board.display_board(@display)
					else
						@display.clear_board
					end
				end
				# Thread::pass
		  	end
		}
		@display_thread.priority = 2
	end

	def start_board_input_thread
		@board_input_thread = Thread.new {
			puts "Board input thread started"

			while(true) do
				col = @display.get_input
				if col then
					verify_game_exists
					puts "Trying #{col}"
					@game.try_move(col, :board)
				end
				# puts "Input thread still running"
				Thread::pass
			end
		}
	end

	def verify_game_exists
		@game = Game.new(self) if @game.nil? or @game.game_over?
	end

	def board_state
		return @game.cur_board unless @game.nil?
		# Pretty lame
		return [0]*42
	end
end