require 'set'

class AltSkynetHelper
  attr_accessor :all_valid_rspsnes, :dict, :alt_tree

  def initialize
    @all_valid_rspnses = Set.new
    @alt_tree = Hash.new { |h, k| h[k] = [] }
    @dict = File.readlines("dictionary.txt").map(&:chomp)

    nil
  end

  def inspect
  end

  def valid_rspnses(word_length)
    dict.select! { |word| word.length == word_length}
    dict.each do |word|
      dstnct_ltr_combos(word).each do |dstnct_ltr_combo|
        valid_rspns = pre_board(word.dup, dstnct_ltr_combo)
        p valid_rspns
        @all_valid_rspnses.add(valid_rspns)


        #alt_tree[valid_rspns] << word #first time this possible board comes up,
          #best_final_board is just the word
        #unless all_valid_rspnses.add?(valid_rspns)
          #this is what happens when this board has already come up
          alt_tree[valid_rspns] << word #IF the word is superior depth, or if equal, append
          #we don't know how to deal with depth this style yet
          #may only need to worry about depth FROM this point, rather than total
          #interesting that guessed letters hasn't come up yet either
          #maybe we just assume they've guessed everything that's not in this word?
          #so far haven't done anything recursive-looking either...
        #end

        #WAIT
        #maybe all i have to do is build the tree, from the full words
        #all the way up to their blank roots
        #that will give the depths and all the possible forks...
        #so i shouldn't just do all the different sized combinations at once

      end
    end

    @all_valid_rspnses
  end

  def pre_board(word, dstnct_ltrs_drppd_combo)
    dstnct_ltrs_drppd_combo.each do |dstnct_ltr_drppd|
      word.gsub!(dstnct_ltr_drppd, "-")
    end

    word
  end

  def dstnct_ltrs(word)
    word.split("").uniq
  end

  def dstnct_ltr_combos(word)
    dstnct_ltr_combos = []
    dstnct_ltrs = dstnct_ltrs(word)
    (1..dstnct_ltrs.length).each do |drppd_ltr_count|
      p dstnct_ltrs.combination(drppd_ltr_count).to_a
      dstnct_ltr_combos += dstnct_ltrs.combination(drppd_ltr_count).to_a
    end

    dstnct_ltr_combos
  end

end
