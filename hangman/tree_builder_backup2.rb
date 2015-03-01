require 'pry'
#require 'set'
require 'sqlite3'
require 'singleton'
require 'yaml'

class Regexp
  def +(r)
    Regexp.new(source + r.source)
  end
end

class Skynet  < SQLite3::Database
  #attr_accessor :dict, :best_depth, :best_final_boards, :hangman_tree
  include Singleton

  def initialize
    super('reveals.db')
    self.results_as_hash = true
    self.type_translation = true
    #@dict = File.readlines("dictionary.txt").map(&:chomp)
    #@hangman_tree = Hash.new { |h, k| h[k] = [] }

    nil
  end

  def inspect
  end

  def build_tree(word_length)
    dict = File.readlines("dictionary.txt").map(&:chomp)
    dict.select! { |word| word.length == word_length }
    board = "-" * word_length
    ('a'..'z').each do |first_gssd_ltr|
      build_tree_rec(first_gssd_ltr, board, dict, [], best_depth = 1)
    end

    #inspect_hangman_tree
    nil
  end

  # def inspect_hangman_tree
  #   @hangman_tree.each { |h, k| puts "#{h} => #{k}" }
  # end

  def build_tree_rec(gssd_ltr, board, dict, gssd_ltrs, best_depth = 1)
    best_words = []
    cur_gssd_ltrs = gssd_ltrs.dup + [gssd_ltr]
    valid_rspnses(gssd_ltr, board, dict, cur_gssd_ltrs).each do |rspns|
      fltrd_dict = fltr_dict(dict, rspns, cur_gssd_ltrs, board)
      if ungssd_ltr_in_dict(fltrd_dict, cur_gssd_ltrs).empty?
        best_words << rspns.dup if cur_gssd_ltrs.count >= best_depth
        best_depth = cur_gssd_ltrs.count if cur_gssd_ltrs.count > best_depth
      else
        ungssd_ltr_in_dict(fltrd_dict, cur_gssd_ltrs).each do |ungssd_ltr|
          best_depth, new_best_boards = build_tree_rec(ungssd_ltr, rspns, \
            fltrd_dict, cur_gssd_ltrs, best_depth)
          best_words += new_best_boards.dup
          best_words.uniq!
        end
      end
    end
    save_rspns(best_words, gssd_ltr, dict, board, gssd_ltrs) if dict.count > 1

    [best_depth, best_words]
  end

  def save_rspns(best_words, gssd_ltr, dict, board, gssd_ltrs)
    best_words = nonwinning_words(board, gssd_ltr, dict) || dict.dup
    best_idxs = best_words.map { |word| idxs_to_reveal(word, gssd_ltr) }
    unless best_idxs.all?(&:empty?)
      puts "#{gssd_ltrs}, #{gssd_ltr}, #{board} = #{best_idxs} (#{best_words}) remaining dict: #{dict}"
      #self.hangman_tree[[gssd_ltrs, gssd_ltr, board]] = best_idxs
      #save_to_db(gssd_ltrs, gssd_ltr, board, best_idxs)
    end
  end

  def fltr_dict(dict, rspns, cur_gssd_ltrs, board)
    dict = a_dict_fltrd_by_wrong_gsses(dict, rspns, cur_gssd_ltrs)
    a_dict_fltrd_by_reveals(dict, rspns, correct_ltrs(board))
  end

  def save_to_db(gssd_ltrs, gssd_ltr, board, best_idxs)
    Skynet.instance.execute(<<-SQL, gssd_ltrs.to_yaml, gssd_ltr, board, best_idxs.to_yaml)
      INSERT INTO
        reveals (gssd_ltr_combo, gssd_ltr, board, reveal_idx_sets)
      VALUES
        (?, ?, ?, ?)
    SQL
  end

  def find_reveal_rspns_by_id(id)
    d = Skynet.instance.execute('SELECT * FROM reveals WHERE id = :id', id: id)
    show_data(d.first.values)
  end

  def show_data((id, gssd_ltr_combo, gssd_ltr, board, reveal_index_sets))
    p YAML.load(gssd_ltr_combo)
    p gssd_ltr
    p board
    p YAML.load(reveal_index_sets)
  end

  def nonwinning_words(board, gssd_ltr, dict)
    nonwinning_words = []
    dict.each do |word|
      word.split("").each_with_index do |ltr, idx|
        next unless board[idx] = "-"
        if ltr != gssd_ltr
          nonwinning_words << word
          break
        end
      end
    end

    nonwinning_words.empty? ? nil : nonwinning_words
  end

  def idxs_to_reveal(word, gssd_ltr)
    [].tap do |idxs|
      word.split("").each_with_index do |ltr, idx|
        idxs << idx if ltr == gssd_ltr
      end
    end
  end

  def ungssd_ltr_in_dict(dict, gssd_ltrs)
    ungssd_ltr(gssd_ltrs).select do |ungssd_ltr|
      dict.join("").include?(ungssd_ltr)
    end
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

  def all_valid_idx_revelation_perms(ltr, board, dict, gssd_ltrs)
    all_nonconflicting_idx_revelation_perms(board).select do |idx_perm|
      valid_vis_a_vis_dict_and_gssd_ltrs?(board_w_revelations(board, ltr, idx_perm), dict, gssd_ltrs)
    end
  end

  def valid_vis_a_vis_dict_and_gssd_ltrs?(board, dict, gssd_ltrs)
    a_dict_fltrd_by_reveals(dict, board, correct_ltrs(board)).any? do |word|
      !fltr_word_by_wrong_ltrs?(word, board, gssd_ltrs)
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

  def valid_rspnses(gssd_ltr, board, dict, gssd_ltrs)
    all_valid_idx_revelation_perms(gssd_ltr, board, dict, gssd_ltrs).map do |idx_perm|
      board_w_revelations(board, gssd_ltr, idx_perm)
    end
  end

  def ungssd_ltr(gssd_ltrs)
    ('a'..'z').to_a.reject { |ltr| gssd_ltrs.include?(ltr) }
  end

  def wrong_ltrs(board, gssd_ltrs)
    gssd_ltrs.reject { |ltr| board.include?(ltr) }
  end

  def correct_ltrs(board)
    duped_board = board.chars.to_a.uniq
    duped_board.delete("-")
    duped_board
  end

  def a_dict_fltrd_by_reveals(dict, board, correct_ltrs)
    correct_ltrs(board).each do |correct_ltr|
      dict = dict.reject do |word|
        fltr_word_by_correct_ltr?(word, correct_ltr, board)
      end
    end

    dict
  end

  def fltr_word_by_correct_ltr?(word, correct_ltr, board)
    correct_idxs = correct_ltr_idxs(correct_ltr, board)
    word.split("").each_with_index do |ltr, idx|
      return true if correct_idxs.include?(idx) && ltr != correct_ltr
      return true if !correct_idxs.include?(idx) && ltr == correct_ltr
    end

    false
  end

  def a_dict_fltrd_by_wrong_gsses(dict, board, gssd_ltrs)
    dict.reject do |word|
      fltr_word_by_wrong_ltrs?(word, board, gssd_ltrs)
    end
  end

  def fltr_word_by_wrong_ltrs?(word, board, gssd_ltrs)
    word.each_char do |ltr|
      return true if wrong_ltrs(board, gssd_ltrs).include?(ltr)
    end

    false
  end

  def correct_ltr_idxs(correct_ltr, board)
    [].tap do |correct_ltr_idxs|
      board.split("").each_with_index do |ltr, idx|
        correct_ltr_idxs << idx if ltr == correct_ltr
      end
    end
  end

end

skynet = Skynet.instance

binding.pry
