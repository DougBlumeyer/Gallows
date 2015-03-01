class SkynetHelper

  def valid_rspnses(gssd_ltr, board, dict, gssd_ltrs)
    valid_idx_rvl_perms(gssd_ltr, board, dict, gssd_ltrs).map do |idx_perm|
      board_w_rvls(board, gssd_ltr, idx_perm)
    end
  end

  def valid_idx_rvl_perms(ltr, board, dict, gssd_ltrs)
    nonconflicting_idx_rvl_perms(board).select do |idx_perm|
      valid_idx_rvl_perm?(board_w_rvls(board, ltr, idx_perm), dict, gssd_ltrs)
    end
  end

  def board_w_rvls(board, ltr, idx_rvl_perm)
    board_w = board.dup
    idx_rvl_perm.each_with_index do |idx_to_rvl, idx|
      board_w[idx] = ltr if idx_to_rvl == true
    end
    puts "   #{board_w}"
    board_w
  end

  def nonconflicting_idx_rvl_perms(board)
    idx_perms(board.length).select do |ptntl_idx_rvl_perm|
      no_board_conflict?(ptntl_idx_rvl_perm, board)
    end
  end

  def no_board_conflict?(ptntl_idx_rvl_perm, board)
    ptntl_idx_rvl_perm.each_with_index do |rvl_this_idx, idx|
      return false if rvl_this_idx == true && board[idx] != "-"
    end

    true
  end

  def valid_idx_rvl_perm?(board, dict, gssd_ltrs)
    dict_fltrd_by_rvls(dict, board, correct_ltrs(board)).any? do |word|
      !fltr_word_by_wrong_ltrs?(word, board, gssd_ltrs)
    end
  end

  def fltr_dict(dict, rspns, cur_gssd_ltrs, board)
    dict = dict_fltrd_by_wrong_gsses(dict, rspns, cur_gssd_ltrs)
    dict_fltrd_by_rvls(dict, rspns, correct_ltrs(board))
  end

  def dict_fltrd_by_rvls(dict, board, correct_ltrs)
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

  def dict_fltrd_by_wrong_gsses(dict, board, gssd_ltrs)
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

  def correct_ltrs(board)
    duped_board = board.chars.to_a.uniq
    duped_board.delete("-")
    duped_board
  end

  def idx_perms(word_length)
    [false, true].repeated_permutation(word_length).to_a
  end

  def wrong_ltrs(board, gssd_ltrs)
    gssd_ltrs.reject { |ltr| board.include?(ltr) }
  end
end
