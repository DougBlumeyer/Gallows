require 'pry'
require 'sqlite3'
require 'singleton'
require 'yaml'
require_relative 'skynet_helper.rb'

class Skynet < SQLite3::Database
  attr_accessor :sh

  include Singleton

  def initialize
    super('reveals.db')
    self.results_as_hash = true
    self.type_translation = true
  end

  def build_tree(word_length)
    dict = File.readlines("dictionary.txt").map(&:chomp)
    dict.select! { |word| word.length == word_length }
    @sh = SkynetHelper.new
    board = "-" * word_length
    ('a'..'z').each do |first_gssd_ltr|
      build_tree_rec(first_gssd_ltr, board, dict, [], best_depth = 1)
    end

    nil
  end

  def build_tree_rec(gssd_ltr, board, dict, gssd_ltrs, best_depth = 1)
    best_words = []
    cur_gssd_ltrs = gssd_ltrs.dup + [gssd_ltr]
    sh.valid_rspnses(gssd_ltr, board, dict, cur_gssd_ltrs).each do |rspns|
      fltrd_dict = sh.fltr_dict(dict, rspns, cur_gssd_ltrs, board)
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
    best_idxs = best_words.map { |word| idxs_to_rvl(word, gssd_ltr) }
    unless best_idxs.all?(&:empty?)
      puts "#{gssd_ltrs}, #{gssd_ltr}, #{board} = #{best_idxs} (#{best_words}) remaining dict: #{dict}"
      #self.hangman_tree[[gssd_ltrs, gssd_ltr, board]] = best_idxs
      save_to_db(gssd_ltrs, gssd_ltr, board, best_idxs)
    end
  end

  def save_to_db(gssd_ltrs, gssd_ltr, board, best_idxs)
    gssd_ltrs_y, best_idxs_y = gssd_ltrs.to_yaml, best_idxs.to_yaml
    rvl = (<<-SQL)
      INSERT INTO
        reveals (gssd_ltr_combo, gssd_ltr, board, reveal_idx_sets)
      VALUES
        (?, ?, ?, ?)
    SQL
    Skynet.instance.execute(rvl, gssd_ltrs_y, gssd_ltr, board, best_idxs_y)
  end

  def find_rvl_rspns_by_id(id)
    d = Skynet.instance.execute('SELECT * FROM reveals WHERE id = :id', id: id)
    show_data(d.first.values)
  end

  def show_data((id, gssd_ltr_combo, gssd_ltr, board, reveal_idx_sets))
    p YAML.load(gssd_ltr_combo)
    p gssd_ltr
    p board
    p YAML.load(reveal_idx_sets)
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

  def idxs_to_rvl(word, gssd_ltr)
    [].tap do |idxs|
      word.split("").each_with_index do |ltr, idx|
        idxs << idx if ltr == gssd_ltr
      end
    end
  end

  def ungssd_ltr_in_dict(dict, gssd_ltrs)
    ungssd_ltrs(gssd_ltrs).select do |ungssd_ltr|
      dict.join("").include?(ungssd_ltr)
    end
  end

  def ungssd_ltrs(gssd_ltrs)
    ('a'..'z').to_a.reject { |ltr| gssd_ltrs.include?(ltr) }
  end

end

skynet = Skynet.instance

binding.pry
