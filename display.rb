require 'wiringpi'

class BoardIntermediary

    # Pin name | WP num | GPIO num
    SWITCH4     = 0 # 17    # GPIO 0
    COL2        = 1 # 18    # GPIO 1
    SWITCH5     = 2 # 21    # GPIO 2
    SWITCH6     = 3 # 22    # GPIO 3
    COL1        = 4 # 23    # GPIO 4
    COL0        = 5 # 24    # GPIO 5
    ROW2        = 6 # 25    # GPIO 6
    SWITCH3     = 7 # 4     # GPIO 7
    SWITCH1     = 8 # 0     # SDA
    SWITCH2     = 9 # 1     # SCL
    ROW1        = 10 # 8    # CE0
    ROW0        = 11 # 7    # CE1
    SWITCH7     = 12 # 10   # MOSI
    RED_ENABLE  = 13 # 9    # MIS0
    BLUE_ENABLE = 14 # 11   # SCLK
    # Plus two more we're not using

    SWITCHES = [SWITCH1, SWITCH2, SWITCH3, SWITCH4, SWITCH5, SWITCH6, SWITCH7]

    def initialize
        @io = WiringPi::GPIO.new

        # Set all the output pins to outputs.
        @io.mode(ROW0, OUTPUT)
        @io.mode(ROW1, OUTPUT)
        @io.mode(ROW2, OUTPUT)
        @io.mode(COL0, OUTPUT)
        @io.mode(COL1, OUTPUT)
        @io.mode(COL2, OUTPUT)
        @io.mode(RED_ENABLE, OUTPUT)
        @io.mode(BLUE_ENABLE, OUTPUT)

        # Set all the switches to inputs.
        SWITCHES.each { |sw| 
            @io.mode(sw, INPUT)
        }

        @last_read = Time.now
    end

    # Set the LED at the the given row and column to display the given color (including no color, off).
    def display_square(row, col, color)
        return false if row < 0 or col < 0 or row > 5 or col > 6
        return false if color != :red and color != :blue and color != :off

        @io.write(RED_ENABLE, LOW)
        @io.write(BLUE_ENABLE, LOW)

        @io.write(ROW2, row / 4 % 2)
        @io.write(ROW1, row / 2 % 2)
        @io.write(ROW0, row % 2)
        @io.write(COL2, col / 4 % 2)
        @io.write(COL1, col / 2 % 2)
        @io.write(COL0, col % 2)

        @io.write(RED_ENABLE, color == :red ? HIGH : LOW)
        @io.write(BLUE_ENABLE, color == :blue ? HIGH : LOW)

        return true
    end

    # Write 0 to all of the row and column pins, and red enable and blue enable.
    def clear_board
        @io.write(ROW2, 0)
        @io.write(ROW1, 0)
        @io.write(ROW0, 0)
        @io.write(COL2, 0)
        @io.write(COL1, 0)
        @io.write(COL0, 0)

        @io.write(RED_ENABLE, 0)
        @io.write(BLUE_ENABLE, 0)
    end

    # Check if any of the switches are low and return which one. If multiple switches are low, it returns the first one that is low.
    def get_input
        # Don't return if it hasn't been at least 300ms since we last read a value.
        return false if Time.now - @last_read < 0.3
        
        SWITCHES.each_with_index { |sw, i|
            if @io.read(sw) == LOW then
                @last_read = Time.now
                return i
            end
        }

        # No values.
        return false
    end

end

# while true do
#     (0..6).each { |c|
#         (0..5).each { |r|
#             @displaySquare(r,c, :red)
#             sleep(0.5/1000.0)
#         }
#     }
# end
# displaySquare(2,2,:red)