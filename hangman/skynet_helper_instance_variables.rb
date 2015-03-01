class SkynetHelper
  attr_accessor :dict, :rspns, :cur_gssd_ltrs
  attr_reader :gssd_ltr, :board, :gssd_ltrs

  def initialize(gssd_ltr, board, dict, gssd_ltrs)
    @gssd_ltr, @board, @dict, @gssd_ltrs = gssd_ltr, board, dict, gssd_ltrs
  end

  def valid_rspnses
    valid_idx_rvl_perms.map do |idx_perm|
      board_w_rvls(idx_perm)
    end
  end

  def valid_idx_rvl_perms
    nonconflicting_idx_rvl_perms.select do |idx_perm|
      valid_idx_rvl_perm?(board_w_rvls(idx_perm))
    end
  end

  def board_w_rvls(idx_rvl_perm)
    board_w = board.dup
    idx_rvl_perm.each_with_index do |idx_to_rvl, idx|
      board_w[idx] = gssd_ltr if idx_to_rvl == true
    end

    board_w
  end

  def nonconflicting_idx_rvl_perms
    idx_perms(board.length).select do |ptntl_idx_rvl_perm|
      no_board_conflict?(ptntl_idx_rvl_perm)
    end
  end

  def no_board_conflict?(ptntl_idx_rvl_perm)
    ptntl_idx_rvl_perm.each_with_index do |rvl_this_idx, idx|
      return false if rvl_this_idx == true && board[idx] != "-"
    end

    true
  end

  def valid_idx_rvl_perm?(board_w)
    dict_fltrd_by_rvls(board_w, correct_ltrs(board_w)).any? do |word| #or board, for the non-correct_ltrs one?
      !fltr_word_by_wrong_ltrs?(word)
    end
  end

  def fltr_dict(rspns, cur_gssd_ltrs)
    self.rspns, self.cur_gssd_ltrs = rspns, cur_gssd_ltrs
    self.dict = dict_fltrd_by_wrong_gsses
    dict_fltrd_by_rvls(correct_ltrs(board))
  end

  def dict_fltrd_by_rvls(correct_ltrs)
    correct_ltrs.each do |correct_ltr|
      self.dict = dict.reject do |word|
        fltr_word_by_correct_ltr?(word, correct_ltr)
      end
    end

    self.dict
  end

  def fltr_word_by_correct_ltr?(word, correct_ltr)
    correct_idxs = correct_ltr_idxs(correct_ltr)
    word.split("").each_with_index do |ltr, idx|
      return true if correct_idxs.include?(idx) && ltr != correct_ltr
      return true if !correct_idxs.include?(idx) && ltr == correct_ltr
    end

    false
  end

  def dict_fltrd_by_wrong_gsses
    dict.reject do |word|
      fltr_word_by_wrong_ltrs?(word)
    end
  end

  def fltr_word_by_wrong_ltrs?(word)
    word.each_char do |ltr|
      return true if wrong_ltrs.include?(ltr)
    end

    false
  end

  def correct_ltr_idxs(correct_ltr)
    [].tap do |correct_ltr_idxs|
      rspns.split("").each_with_index do |ltr, idx|
        correct_ltr_idxs << idx if ltr == correct_ltr
      end
    end
  end

  def correct_ltrs(board_or_rspns)
    duped_board = board_or_rspns.chars.to_a.uniq
    duped_board.delete("-")
    duped_board
  end

  def idx_perms(word_length)
    [false, true].repeated_permutation(word_length).to_a
  end

  def wrong_ltrs
    gssd_ltrs.reject { |ltr| board.include?(ltr) }
  end
end
