require 'pry'
require 'set'

class Regexp
  def +(r)
    Regexp.new(source + r.source)
  end
end

class SuperComputer
  attr_accessor :dict, :best_depth, :best_final_board

  def initialize
    @dict = File.readlines("dictionary.txt").map(&:chomp)
    #@dict = Set.new(@dict)
    @best_depth = 0
    @best_final_board = nil
  end

  #alright, so i just need an answer for EVERY combination of guessed letter (26),
  #, board (which is a small subset of actual possibilites of 27^word_length,
  # 27 because of the unknown char option, and already guessed letter, which i
  # guess might be another exponential or maybe factorial type thing...?)

  #  This method returns the best possible board to respond to the guess with.
  #  "Best" is by turn depth, assuming the guesser always guesses the most
  #  frequently occurring ltr among remaining words matching the board.
  #
  #  In other words, we make the assumption that the guesser is smart enough
  #  to figure the frequency of letters in a dict subset, but not smart
  #  enough to neutralize our "AI" by also figuring out the guessing path
  #  depths and guessing in a manner designed to minimize it.
  #
  #  In yet other words, the guesser does not realize that we are being evil
  #  and never really choosing a word until the end!
  def super_check(guessed_ltr, board, dict, alrdy_guessed_ltrs)
    @dict = File.readlines("dictionary.txt").map(&:chomp)
    @best_depth = 0
    @best_final_board = nil
    dict.select! { |word| word.length == board.length }
    self.best_final_board = best_final_response_board(guessed_ltr, board, dict, alrdy_guessed_ltrs)
    #puts best_final_board
    #puts best_depth
    #reveal_ltr(guessed_ltr) if best_final_board.include?(guessed_ltr)

    best_final_board
  end

  private

  #def reveal_ltr(guessed_ltr)
  #end

  def best_final_response_board(guessed_ltr, board, dict, alrdy_guessed_ltrs)
    this_path_alrdy_guessed_ltrs = alrdy_guessed_ltrs.dup + [guessed_ltr]
    all_valid_response_boards(guessed_ltr, board, dict, this_path_alrdy_guessed_ltrs).each do |response_board|
      filtered_dict = a_dict_filtered_by_wrong_guesses(dict, response_board, this_path_alrdy_guessed_ltrs)
      filtered_dict = a_dict_filtered_by_reveals(filtered_dict, response_board, all_correctly_guessed_ltrs(board))
      probable_guess = most_freq_ltr(response_board, filtered_dict)
      if probable_guess.nil?
        if this_path_alrdy_guessed_ltrs.count > best_depth ||
          (this_path_alrdy_guessed_ltrs.count == best_depth && rand(2) == 1)
          self.best_final_board = response_board.dup
          self.best_depth = this_path_alrdy_guessed_ltrs.count
        end
      else
        best_final_response_board(probable_guess, response_board, filtered_dict, this_path_alrdy_guessed_ltrs)
      end
    end

    best_final_board
  end

  def all_idx_perms(word_length)
    [false, true].repeated_permutation(word_length).to_a
  end

  def all_nonconflicting_idx_revelation_perms(board)
    all_idx_perms(board.length).select do |potential_idx_revelation_perm|
      no_board_conflict?(potential_idx_revelation_perm, board)
    end
  end

  def no_board_conflict?(ptntl_idx_revelation_perm, board)
    ptntl_idx_revelation_perm.each_with_index do |reveal_this_idx, idx|
      return false if reveal_this_idx == true && board[idx] != "-"
    end

    true
  end

  def all_valid_idx_revelation_perms(ltr, board, dict, alrdy_guessed_ltrs)
    all_nonconflicting_idx_revelation_perms(board).select do |idx_perm|
      valid_vis_a_vis_dict_and_guessed_ltrs?(board_w_revelations(board, ltr, idx_perm), dict, alrdy_guessed_ltrs)
    end
  end

  def valid_vis_a_vis_dict_and_guessed_ltrs?(board, dict, alrdy_guessed_ltrs)
    a_dict_filtered_by_reveals(dict, board, all_correctly_guessed_ltrs(board)).any? do |word|
      !contains_any_ltrs_that_are_wrong_guesses(word, board, alrdy_guessed_ltrs) #&&
    end
  end

  def board_w_revelations(board, ltr, idx_revelation_perm)
    board_w = board.dup
    idx_revelation_perm.each_with_index do |idx_to_reveal, idx|
      board_w[idx] = ltr if idx_to_reveal == true
    end

    board_w
  end

  def to_regex(board)
    regex_str = /\A/
    board.each_char { |idx| regex_str += ( idx == "-" ? /\w/ : /#{idx}/ ) }

    regex_str + /\z/
  end

  def all_valid_response_boards(guessed_ltr, board, dict, alrdy_guessed_ltrs)
    all_valid_idx_revelation_perms(guessed_ltr, board, dict, alrdy_guessed_ltrs).map do |idx_perm|
      board_w_revelations(board, guessed_ltr, idx_perm)
    end
  end

  def most_freq_ltr(board, dict)
    ltr_hash = Hash.new(0)
    dict.each do |word|
      board.split("").each_with_index { |ltr, idx| ltr_hash[word[idx]] += 1 if ltr == "-" }
    end
    key, max_ltr_cnt = ltr_hash.sort_by { |ltr, cnt| cnt }.last

    most_freq_ltrs = ltr_hash.select { |ltr, cnt| cnt == max_ltr_cnt }
    most_freq_ltr = most_freq_ltrs.keys.sample

    return nil if most_freq_ltr == []
    most_freq_ltr
  end

  def a_dict_filtered_by_wrong_guesses(dict, board, alrdy_guessed_ltrs)
    dict.reject do |word|
      contains_any_ltrs_that_are_wrong_guesses(word, board, alrdy_guessed_ltrs)
    end
  end

  def contains_any_ltrs_that_are_wrong_guesses(word, board, alrdy_guessed_ltrs)
    word.each_char do |ltr|
      return true if all_wrong_guesses(board, alrdy_guessed_ltrs).include?(ltr)
    end

    false
  end

  def all_wrong_guesses(board, alrdy_guessed_ltrs)
    alrdy_guessed_ltrs.reject { |ltr| board.include?(ltr) }
  end

  def all_correctly_guessed_ltrs(board)
    duped_board = board.each_char.uniq
    duped_board.delete("-")
    duped_board
  end

  def a_dict_filtered_by_reveals(dict, board, all_correctly_guessed_ltrs)
    all_correctly_guessed_ltrs(board).each do |correctly_guessed_ltr|
      dict = dict.reject do |word|
        filter_this_word_by_this_correctly_guessed_ltr?(word, correctly_guessed_ltr, board)
      end
    end

    dict
  end

  def filter_this_word_by_this_correctly_guessed_ltr?(possible_secret_word, correctly_guessed_ltr, board)
    correct_indices = correctly_guessed_ltrs_indices(correctly_guessed_ltr, board)
    possible_secret_word.split("").each_with_index do |ltr, idx|
      return true if correct_indices.include?(idx) && ltr != correctly_guessed_ltr
      return true if !correct_indices.include?(idx) && ltr == correctly_guessed_ltr
    end

    false
  end

  def correctly_guessed_ltrs_indices(correctly_guessed_ltr, board)
    correct_indices = []
    board.split("").each_with_index do |ltr, idx|
      correct_indices << idx if ltr == correctly_guessed_ltr
    end

    correct_indices
  end

end

hal = SuperComputer.new
#binding.pry
