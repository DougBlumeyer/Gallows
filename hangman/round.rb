class Game
  attr_accessor :guesser, :checker, :board, :wrong_letters_guessed,
                :wrong_guesses_count, :winner, :loser
  attr_reader   :max_wrong_guesses

  def initialize(guesser, checker, max_wrong_guesses=8)
    @guesser = guesser
    @guesser.game = self

    @checker = checker
    @checker.game = self

    @winner = nil
    @loser = nil

    @max_wrong_guesses = max_wrong_guesses
    @wrong_guesses_count = 0

    @board = nil
    @wrong_letters_guessed = " "*26
  end

  def play
    game_setup

    until game_over?
      render_board

      #print "#{guesser.name}'s turn. "
      guess = guesser.guess

      break if guess.nil?
      break if guess == "quit"

      positions = checker.check(guess)
      break if positions == "quit"
      guesser.learn_from_guess(guess, positions)
    end

    game_over
  end

  def game_setup
    checker.pick_secret_word
    guesser.one_time_filter_by_length
  end

  def game_over
    #self.wrong_guesses_count = max_wrong_guesses if self.wrong_guesses_count > max_wrong_guesses
    self.board = checker.secret_word
    render_board

    if winner.nil?
      puts "Nobody wins! "
    else
      puts "#{winner.name} wins!"
      puts "#{winner.points[loser.name]} round#{winner.points > 1 ? "s" : ""} won against #{loser.name} so far today."
    end
  end

  def game_over?
    if wrong_guesses_count == max_wrong_guesses || \
      wrong_letters_guessed == ('a'..'z').to_a
      self.winner = checker
      self.loser = guesser
      self.winner.points[loser.name] += 1
      self.loser.losses[winner.name] += 1
      return true
    elsif !board.include?("-")
      self.winner = guesser
      self.loser = checker
      self.winner.points[loser.name] += 1
      self.loser.losses[winner.name] += 1
      return true
    else
      false
    end
  end

  def render_board
    system("clear")
    puts "\n"
    print "#{board}#{" " * (19 - board.length)}"
    print "Guess #{wrong_guesses_count+1}/#{max_wrong_guesses}\n" if winner.nil?
    print "Guess #{wrong_guesses_count}/#{max_wrong_guesses}\n" unless winner.nil?
    puts "#{"1234567890123456789".split("").take(board.length).join("")}"
    puts "[#{wrong_letters_guessed}]"
    puts ""
  end

  def instructions
    puts "\nIf it occurs at more than one position, "
    puts "separate the positions with commas."
    puts "\nFor example:\n\n    > 2\n    > 1,4,11"
    puts "\nJust press Return if the letter doesn't occur."
    puts "And please don't lie!"
    print "You can type \"quit\" to quit this round at any time. "
  end

end
