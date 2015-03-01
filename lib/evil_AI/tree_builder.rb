require 'pry'
require 'sqlite3'
require 'singleton'
require 'yaml'
#require_relative 'skynet_helper_instance_variables.rb'
require_relative 'skynet_helper.rb'
require_relative 'dopple_arlnten_skynet_helper.rb'

class Skynet < SQLite3::Database
  attr_accessor :sh, :aash

  include Singleton

  def initialize
    super('reveals.db')
    self.results_as_hash = true
    self.type_translation = true
  end

  ######UNCOMMENT ME WHEN USING NON-INSTANCE-VARIABLES VS OF SKYNET_HELPER ###

  def build_tree(word_length)
    dict = File.readlines("dictionary.txt").map(&:chomp)
    dict.select! { |word| word.length == word_length }
    @sh = SkynetHelper.new
    @aash = AltAltSkynetHelper.new
    @aash.build_dict_tree(word_length)
    board = "-" * word_length
    ('a'..'z').each do |first_gssd_ltr|
      build_tree_rec(first_gssd_ltr, board, dict, [], best_depth = 1)
    end

    #build_tree_rec("", board, dict, [], best_depth = 1)

    nil
  end

  def fltrd_alt_tree(alt_tree_boards, cur_gssd_ltrs) #WE DO NEED TO FILTER BY ALL THE CUR_GSSD_LTRS
    selected_alt_tree_boards = []
    alt_tree_boards.each do |alt_tree_board|
      select_this_board = true
      cur_gssd_ltrs.each do |cur_gssd_ltr|
        select_this_board = false unless alt_tree_board.include?(cur_gssd_ltr)
      end
      selected_alt_tree_boards << alt_tree_board if select_this_board
    end

    selected_alt_tree_boards

    #WAIT HAHAHAHAH IM SUPPOSED TO FILTER OUT ALL BUT THE ONES THAT INCLUDE THE LETTER...
    #so i just switched if to unless
  end

  def build_tree_rec(gssd_ltr, board, dict, gssd_ltrs, best_depth = 1)
    best_words = []
    cur_gssd_ltrs = gssd_ltrs.dup + [gssd_ltr]
    #cur_gssd_ltrs = gssd_ltrs.dup
    #cur_gssd_ltrs += [gssd_ltr] unless gssd_ltr == ""
    #sh.valid_rspnses(gssd_ltr, board, dict, cur_gssd_ltrs).each do |rspns|
    puts "\ncur_gssd_ltrs: #{cur_gssd_ltrs}"
    #puts "just gssd ltr: #{gssd_ltr}"
    puts "board: #{board}" #is this the board AFTER the gssd_ltr is applied?
    #the way this is working now is not necessarily wrong, i haven't confirmed or disconfirmed that yet...
    #er, wait, no, it is wrong, b/c ["a"], d, -d = [[1], [1]] (["ed", "id"]) remaining dict: ["ed", "id"]...
    #that's definitely not how i originally intended.
    #the gssd_ltr should not be in the board, that should be for the next board
    #puts "aash.alt_tree[board]: #{aash.alt_tree[board]}\n"
    #puts "aash.alt_tree[board].reject... #{aash.alt_tree[board].reject { |brd| brd.include?(gssd_ltr)} }"
    puts "fltrd_alt_tree(aash.alt_tree[board], cur_gssd_ltrs) #{fltrd_alt_tree(aash.alt_tree[board], cur_gssd_ltrs)}"
    #AH HA, HERE'S THE PROBLEM - AASH.ALT_TREE[BOARD] is fine and well, but need to filter it by gssd_ltr (or maybe cur_gssd_ltrs??)
    #aash.alt_tree[board].reject { |brd| brd.include?(gssd_ltr)}.each do |rspns|
    fltrd_alt_tree(aash.alt_tree[board], cur_gssd_ltrs).each do |rspns|
      #puts "#{gssd_ltrs}, #{gssd_ltr}, #{rspns}"
      fltrd_dict = sh.fltr_dict(dict, rspns, cur_gssd_ltrs, board) #...so something weird is going on here...
      if ungssd_ltrs_in_dict(fltrd_dict, cur_gssd_ltrs).empty?
        #best_words << rspns.dup if cur_gssd_ltrs.count >= best_depth
        if cur_gssd_ltrs.count >= best_depth
          best_words << rspns.dup
          puts "\n  adding boards in here, b/c basecased: #{rspns}"
          puts "  best_words is now #{best_words}"
        end
        best_depth = cur_gssd_ltrs.count if cur_gssd_ltrs.count > best_depth
      else
        ungssd_ltrs_in_dict(fltrd_dict, cur_gssd_ltrs).each do |ungssd_ltr|
          #puts "just gssd ltr: #{ungssd_ltr}"
          best_depth, new_best_boards = build_tree_rec(ungssd_ltr, rspns, \
            fltrd_dict, cur_gssd_ltrs, best_depth)
          best_words += new_best_boards.dup
          puts "\n  adding boards in here, coming out of rec: #{new_best_boards}"
          best_words.uniq!
          puts "  best_words is now #{best_words}"
        end
      end
    end
    #puts "#{board} is board right before the save_rspns... first char is -?"
    save_rspns(best_words, gssd_ltr, dict, board, gssd_ltrs) if dict.count > 1

    [best_depth, best_words]
  end

  ######UNCOMMENT ME WHEN USING INSTANCE-VARIABLES VS OF SKYNET_HELPER ###

  # def build_tree(word_length)
  #   dict = File.readlines("dictionary.txt").map(&:chomp)
  #   dict.select! { |word| word.length == word_length }
  #   board = "-" * word_length
  #   ('a'..'z').each do |first_gssd_ltr|
  #     build_tree_rec(first_gssd_ltr, board, dict, [], best_depth = 1)
  #   end
  #
  #   nil
  # end
  #
  # def build_tree_rec(gssd_ltr, board, dict, gssd_ltrs, best_depth = 1)
  #   best_words = []
  #   cur_gssd_ltrs = gssd_ltrs.dup + [gssd_ltr]
  #   sh = SkynetHelper.new(gssd_ltr, board, dict, gssd_ltrs)
  #   sh.valid_rspnses.each do |rspns|
  #     fltrd_dict = sh.fltr_dict(rspns, cur_gssd_ltrs) #so there are multiple of rspns and cur_gssd_ltrs for each skynethelper, though only one at a time. and a rspns is distinct from the board, then.
  #     if ungssd_ltrs_in_dict(fltrd_dict, cur_gssd_ltrs).empty?
  #       best_words << rspns.dup if cur_gssd_ltrs.count >= best_depth
  #       best_depth = cur_gssd_ltrs.count if cur_gssd_ltrs.count > best_depth
  #     else
  #       ungssd_ltrs_in_dict(fltrd_dict, cur_gssd_ltrs).each do |ungssd_ltr|
  #         best_depth, new_best_boards = build_tree_rec(ungssd_ltr, rspns, \
  #         fltrd_dict, cur_gssd_ltrs, best_depth)
  #         best_words += new_best_boards.dup
  #         best_words.uniq!
  #       end
  #     end
  #   end
  #   save_rspns(best_words, gssd_ltr, dict, board, gssd_ltrs) if dict.count > 1
  #
  #   [best_depth, best_words]
  # end

  def save_rspns(best_words, gssd_ltr, dict, board, gssd_ltrs)
    puts "\n    BEST WORDS WOULD HAVE BEEN: #{best_words}"
    best_words = nonwinning_words(board, gssd_ltr, dict) || dict.dup
    puts "    BUT NOW IT'S #{best_words}"
    #wait WTF is this doing? is this not just like,
    #completely overriding whatever is coming in from best_words the parameter?
    #i mean, in this case:
    # ["a"], d, -- = [[1], [], [], [], [], [], [], []]
    # (["ad", "ah", "am", "an", "as", "at", "aw", "ax"])
    #we do want ah, am, an, as, at, aw, ax and NOT ad...
    #but... seems like ... i'm just so confused about what this was for...

    #also we now have a bug where the first char of board is always "-" ...
    #["a", "b", "c"], i, -bac- = [[4], []] ... that should be a as in abaci
    #ookay, fixed that one, had a setter instead of == in a conditional in nonwinnign words...

    best_idxs = best_words.map { |word| idxs_to_rvl(word, gssd_ltr) }
    puts "    BEST INDXS (ALL EMPTY? -> NO DB ENTRY): #{best_idxs}"
    unless best_idxs.all?(&:empty?)
      puts "    #{gssd_ltrs}, #{gssd_ltr}, #{board} = #{best_idxs}"
      puts "    (#{best_words})"
      puts "    remaining dict: #{dict}"
      #self.hangman_tree[[gssd_ltrs, gssd_ltr, board]] = best_idxs
      #save_to_db(gssd_ltrs, gssd_ltr, board, best_idxs)
    end
  end

  # ["a", "b"], c, aba-- = [[3], [3], [], [], [], []]
  # (["abaci", "aback", "abaft", "abase", "abash", "abate"])
  # this works because if you reveal c, the player will guess i next, you'll
  #   not reveal it, then they'll guess k and the game is over, so they have
  #   one wrong guess remaining
  # and if you DON'T reveal c, the player will guess s or t next, you'll not
  # reveal it, ...WAIT it doesn't work because what if they guess t first?
  # their next guess of s doesn't distinguish between the two remaining options
  # because s is in the same position (unlike t which is in different pos's)
  # i mean, this is weird, but it looks like "best words" are the exact opposite
  # and when we're replacing it with nonwinning words, we mean to be subtracting
  # them from it... although actually what we want is to just not add an entry
  # to the database

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

  def self.last_insert_row_id
    show_data(Skynet.instance.last_insert_row_id.first.values)
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
        next unless board[idx] == "-"
        if ltr != gssd_ltr
          nonwinning_words << word
          break
        end
      end
    end

    puts "    NONWINNING WORDS: #{nonwinning_words}"

    nonwinning_words.empty? ? nil : nonwinning_words
  end

  def idxs_to_rvl(word, gssd_ltr)
    [].tap do |idxs|
      word.split("").each_with_index do |ltr, idx|
        idxs << idx if ltr == gssd_ltr
      end
    end
  end

  def ungssd_ltrs_in_dict(dict, gssd_ltrs)
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
