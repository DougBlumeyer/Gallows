class ComputerPlayer < Player
  attr_accessor :dictionary, :secret_word, :name, :possible_secret_words,
                :cheapo_dictionary, :temp_dictionary, :ai_level, :hal

  def initialize(name, ai_level = :easy)
    @secret_word = nil
    @dictionary
    @cheapo_dictionary
    @temp_dictionary
    @possible_secret_words = []
    @ai_level = ai_level
    @hal = SuperComputer.new if ai_level == :hard
    super(name)
    #puts "AI LEVEL: #{ai_level}"
  end

  def pick_secret_word
    self.dictionary = File.readlines("dictionary.txt").map(&:chomp)
    self.secret_word = dictionary.sample
    #puts "#{@secret_word}"
    puts "#{@name} has chosen the secret word. (Return to continue)"
    self.game.board = "-"*secret_word.length
    gets
  end

  def check(guess)

    #puts "dictionary"
    #p @dictionary
    if ai_level == :medium
      self.cheapo_dictionary = dictionary.select do |word|
        word.length == game.board.length && !word.include?(guess)
      end.dup

      self.temp_dictionary = dictionary.select do |word|
        word.length == game.board.length && word.include?(guess)
        #that was working toward the computer being free to switch it to a different
        #word which contains the letter but is less revealing, but then we're just approaching
        #something like contact... i mean why wouldn't he pick the best # of letters
        #at the beginning, and pick the word with the most branches
      end.dup

      #and here create a different temp_dictionary using similar logic to learn_from_guess
      #to see how many possibilities if he just reveals the letter
      correct_positions = []
      secret_word.split("").each_with_index do |letter, i|
        correct_positions << i+1 if letter == guess
      end

      self.temp_dictionary = temp_dictionary.reject do |word|
        filter_this_word?(word, guess, correct_positions)
      end.dup
      # @cheapo_dictionary = @cheapo_dictionary.reject do |word|
      #   filter_this_word?(word, guess, correct_positions)
      # end

      #puts "\ncheapo switcheroo dictionary"
      #puts @cheapo_dictionary
      #puts @cheapo_dictionary.count

      #puts "\nwhat dict will be filtered down to if you give this letter away"
      #puts @temp_dictionary
      #puts @temp_dictionary.count

      #okay hal should only change his word if it results in keeping the possibilities larger
      if cheapo_dictionary.count > temp_dictionary.count
        self.dictionary = cheapo_dictionary.dup
        self.secret_word = dictionary.sample unless dictionary.empty?
      else
        self.dictionary = temp_dictionary.dup
      end

      #puts "\nsecret word"
      #puts @secret_word
    elsif ai_level == :hard
      secret_word = hal.super_check(guess, game.board, dictionary, all_correctly_guessed_ltrs(game.board) + all_correctly_guessed_ltrs(game.wrong_letters_guessed))

    end

    correct_positions = []
    flag_at_least_one_match = false
    secret_word.split("").each_with_index do |letter, i|
      if letter == guess
        game.board[i] = letter
        correct_positions << (i + 1)
        flag_at_least_one_match = true
      end
    end

    if flag_at_least_one_match
      game.wrong_letters_guessed[guess.ord - 'a'.ord] = "-"
    else
      game.wrong_letters_guessed[guess.ord - 'a'.ord] = guess
      game.wrong_guesses_count += 1
    end

    correct_positions
  end

  def all_correctly_guessed_ltrs(board)
    duped_board = board.split("").uniq
    duped_board.delete("-")
    duped_board
  end

  def learn_from_guess(guess, correct_positions)
    if correct_positions == []
      self.possible_secret_words =
      possible_secret_words.reject do |possible_secret_word|
        possible_secret_word.include?(guess)
      end
    else
      self.possible_secret_words =
      possible_secret_words.reject do |possible_secret_word|
        filter_this_word?(possible_secret_word, guess, correct_positions)
      end
    end
  end

  def filter_this_word?(possible_secret_word, guess, positions)
    filter = false
    possible_secret_word.split("").each_with_index do |ltr, i|
      filter = true if positions.include?(i + 1) && ltr != guess
      filter = true if !positions.include?(i + 1) && ltr == guess
    end
    filter
  end

  def guess
    attempt = most_frequent_letter

    if attempt.nil?
      print "#{@name} doesn't think you picked a real word! "
      gets.chomp
    else
      puts "#{@name} guesses '#{attempt}'."
    end
    sleep(0.5)

    attempt
  end

  def one_time_filter_by_length
    self.dictionary = File.readlines("dictionary.txt").map(&:chomp)
    #puts "RESET MUH DICT"
    #p possible_secret_words
    #p possible_secret_words.length
    #p game.board.length
    self.possible_secret_words = dictionary.select { |word| word.length == game.board.length}.dup
    #p possible_secret_words
    #p possible_secret_words.length
  end

  def most_frequent_letter
    ltr_hash = Hash.new(0)
    possible_secret_words.each do |word|
      game.board.split("").each_with_index do |letter, index|
        ltr_hash[word[index]] += 1 if letter == "-"
      end
    end

    most_frequent_letters = ltr_hash.sort_by { |h, k| k }
    attempt, k = most_frequent_letters.last

    attempt
  end

end
