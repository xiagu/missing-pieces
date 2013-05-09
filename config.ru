require 'em-websocket'
require 'json'
require './game.rb'

class SocketManager

	attr_reader :player, :observers

	def initialize
		@player = nil
		@observers = []
		@game = nil
	end	

	def run
		EM.run {

			EM::WebSocket.run(:host => "0.0.0.0", :port => 3000) do |ws|
				ws.onopen { |handshake| 
					puts "WebSocket connection open"
					ws.send "Hello client, you connected to #{handshake.path}"

					# Add to list of clients
					if @player.nil? then 
						@player = ws

						# TODO: Don't always make a new one, the board could have started a game and we should attach to it
						@game = Game.new(self)

						@game.conduct
					else
						@observers.push ws
					end

				}

				ws.onclose { 
					puts "Connection closed"

					# Remove from list of connected clients
					if @player == ws then
						@player = @observers.shift
						# If there's nobody left then end the game
						@game.end_game if @player.nil?
					else
						@observers.delete ws
					end
				}

				ws.onmessage { |message| 
					puts "Received message: #{message}"
					
					msg = JSON.parse(message)

					# Don't do anything if it's not from our main player
					if @player == ws then
						if msg[:type] == :new_move then
							@game.try_move(msg[:column], :website)
						end
					end
				}
			end
		}
	end

	# Sends the state of the game we have to all our clients.
	def send_state(board, cur_player)
		return false if @player.nil?
		
		@player.send({:board => board, :your_turn => cur_player == :website}.to_json)
	end	

end