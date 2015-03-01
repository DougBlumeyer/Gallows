class HumanPlayer < Player
  attr_accessor :secret_word, :name, :flag_instructions_given

  def initialize(name, flag_instructions_given)
    @secret_word = nil
    @flag_instructions_given = flag_instructions_given
    super(name)
  end

  def pick_secret_word
    print "\nWhat is the length of your secret word, #{@name}? "
    self.secret_word = "-"*(gets.chomp.to_i)
    until @secret_word.length.between?(1,18)
      print "Please choose a length between 1 and 18 letters: "
      self.secret_word = "-"*(gets.chomp.to_i)
    end
    self.game.board = secret_word
  end

  def guess
    successful_input = false
    until successful_input
      print "#{name} - guess a letter"
      if flag_instructions_given == false
        print " (or type \"quit\" to quit at any time.)"
        self.flag_instructions_given = true
      end
      print ": "
      input_attempt = gets.chomp
      if input_attempt == "quit"
        successful_input = true
      elsif !('a'..'z').include?(input_attempt)
        puts "That's not a letter. Try again."
      elsif game.board.include?(input_attempt)
        puts "You already found that one..."
      elsif game.wrong_letters_guessed.include?(input_attempt)
        puts "You already tried that one..."
      else
        successful_input = true
      end
    end
    input_attempt
  end

  def check(guess)
    print "\nAt which positions in your secret word does this letter occur, #{name}? "

    unless flag_instructions_given
      game.instructions
      self.flag_instructions_given = true
    end

    input_attempt = []
    1.times do
      input_attempt = gets.chomp
      if input_attempt != "quit"
        input_attempt = input_attempt.split(",").map(&:to_i)
        #p input_attempt
        #p "#{game.board[input_attempt[0] - 1]}"
        if input_attempt.empty?
          self.game.wrong_guesses_count += 1
          self.game.wrong_letters_guessed[guess.ord - 'a'.ord] = guess
        elsif input_attempt.all? { |input| input.between?(1, game.board.length) } #&& input_attempt.none? { |index| game.board[index - 1] != " " }
          repeater = false
          input_attempt.each do |index|
            if game.board[index - 1] != "-"
              #puts "WTF INDEX #{index} G.B.[WHATEV] #{game.board[index - 1]}"
              repeater = true
            end
          end
          if repeater
            print "You already revealed the letter in that position. Please try again: "
            redo
          end
          input_attempt.each { |index| self.game.board[index - 1] = guess }
        elsif input_attempt == "quit"
        else
          print "Something's not right with your input. Please try again: "
          redo
        end
      end
    end

    return input_attempt
  end

  def learn_from_guess(guess, positions)
  end

  def one_time_filter_by_length
  end

end
