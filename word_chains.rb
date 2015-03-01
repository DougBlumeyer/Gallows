require 'set'

class WordChainer
  def initialize(dictionary_file_name)
    @dictionary = File.readlines("dictionary.txt").map(&:chomp)
    @dictionary = Set.new(@dictionary)
  end

  def adjacent_words(word)
    [].tap do |adjacent_words|
      word.split("").each_with_index do |ltr, i|
        ('a'..'z').each do |sub_ltr|
          next if sub_ltr == ltr
          test_word = word.dup
          test_word[i] = sub_ltr
          adjacent_words << test_word if @dictionary.include?(test_word)
        end
      end
    end
  end

  def run(source,target)
    @current_words = [source]
    @all_seen_words = { source => nil }

    xplr_crnt_w until @current_words.empty? || @all_seen_words.include?(target)

    build_path(target)
  end

  def xplr_crnt_w
    new_current_words = []
    @current_words.each do |current_word|
      adjacent_words(current_word).each do |adjacent_word|
        next if @all_seen_words.include?(adjacent_word)
        @all_seen_words[adjacent_word] = current_word
        new_current_words << adjacent_word
      end
    end

    # puts ""
    # new_current_words.each do |new_current_word|
    #   puts "#{@all_seen_words[new_current_word]} -> #{new_current_word}"
    # end

    @current_words = new_current_words
  end

  def build_path(t)
    @all_seen_words[t] == nil ? [t] : build_path(@all_seen_words[t]) << t
  end

end

if __FILE__ == $PROGRAM_NAME
  wc = WordChainer.new("dictionary.txt")
  #puts wc.adjacent_words("fire")
  p wc.run("fire","bank")
end
