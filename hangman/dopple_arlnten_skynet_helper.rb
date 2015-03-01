class AltAltSkynetHelper
  attr_accessor :all_valid_rspsnes, :dict, :alt_tree

  def initialize
    #@all_valid_rspnses = Set.new
    @alt_tree = Hash.new { |h, k| h[k] = [] }
    @dict = File.readlines("dictionary.txt").map(&:chomp)
    #@dict.each { |word| @alt_tree[word] = nil }
    #nil
  end

  def inspect
  end

  def build_dict_tree(word_length)
    @dict.select! { |word| word.length == word_length}
    @dict.each do |word|
      #puts "buildin' dict tree for #{word}"
      build_dict_tree_rec(word)
    end
  end

  def build_dict_tree_rec(word)
    dstnct_ltrs = dstnct_ltrs(word)
    #puts "word: #{word} dstnct_ltrs"
    #p dstnct_ltrs
    return if dstnct_ltrs.empty?
    dstnct_ltrs.each do |dstnct_ltr|
      #next if dstnct_ltr == "-"
      board = word.gsub(dstnct_ltr, "-")
      #@alt_tree[board] = word
      #@alt_tree[word] << board
      @alt_tree[board] << word unless @alt_tree[board].include?(word)
      #build_dict_tree_rec(board) unless @alt_tree.include?(board)
      build_dict_tree_rec(board)
    end
  end

  def dstnct_ltrs(word)
    output = word.split("").uniq
    output.delete("-")
    output
  end

end
