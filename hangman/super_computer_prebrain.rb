def create_prebrain
  prebrain = {}
  alrdy_guessed_ltr_combos.each do |alrdy_guessed_ltr_combo| #just guessed is the last one
    board_possibilities.each do |board_possibility| #word length is accounted for inside board_possibilities
      prebrain[[aldry_guessed_ltr_combo, board_possibility]] = array_of_pos_to_reveal
    end
  end
end

def alrdy_guessed_ltr_combos
  already_guessed_ltr_combos = [[]]
  26.times do
    new_ltr_combos = []
    already_guessed_ltr_combos.each do |ltr_combo|
      ('a'..'z').each do |ltr|
        new_ltr_combo = ltr_combo + [ltr]
        new_ltr_combo.sort!
        puts new_ltr_combo
        new_ltr_combos << new_ltr_combo unless new_ltr_combos.include?(new_ltr_combo)
      end
    end
    already_guessed_ltr_combos.delete([])
    already_guessed_ltr_combos += new_ltr_combos.dup
  end

  #or would it be faster to, after getting halfway, just take each one once and add its inverse?
  already_guessed_ltr_combos
end

def test2
  [].tap { |op| (1..26).each { |l| op += ('a'..'z').to_a.combination(l).to_a }
end
