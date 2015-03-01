require_relative 'round.rb'
require_relative 'player.rb'
require_relative 'computer_player.rb'
require_relative 'human_player.rb'
require_relative 'super_computer_player.rb'

class Hangman
  attr_accessor :round, :players, :default_setup, :is_rematch

  def initialize
    @players = {}
    @round
    @default_setup = false
    @is_rematch = false
  end

  def play
    setup
    collect_players

    input = 'y'
    until input != 'y'
      if default_setup
        default_setup_round
      elsif !is_rematch
        setup_round
      end
      self.is_rematch = false
      round.play
      print "Rematch, same guesser/checker? (y/n) "
      input = gets.downcase.chomp[0]
      if input != 'y'
        change_settings_prompt
        input = 'y'
      else
        setup_rematch
      end
    end

    closing
  end

  def setup_rematch
    self.is_rematch = true
    guesser = round.guesser
    checker = round.checker
    max_wrong_guesses = round.max_wrong_guesses
    self.round = Game.new(guesser, checker, max_wrong_guesses)
  end

  def change_settings_prompt
    1.times do
      puts "\nAny new players (y/n)?"
      print "You can just push Return to keep the max guess count and default to "
      print "a random pairing, " if players.length > 2
      print "switching roles, " if players.length == 2
      print "\n'n' to specify settings, or 'q' to quit. "
      input = gets.downcase.chomp[0]
      if input == nil
        self.default_setup = true
      elsif input == 'y'
        collect_players
      elsif input == 'q'
        closing
      elsif input == 'n'
        break
      else
        print "Say what? "
        redo
      end
    end
  end

  def closing
    system("clear")
    puts "\nLEADERBOARD\n          "
    players.each { |player| print "#{player.name.split("").take(8).join("")  }" }
    players.each do |player|
      print "\n#{player.name.split("").take(8).join("")}  \n    WINS: "
      players.each do |other_player|
        print "#{(9 - player.points[other_player.name].to_s.length) * " "}#{player.points[other_player.name]} "
      end
      print "\n#{player.name.split("").take(8).join("")}  \n  LOSSES: "
      players.each do |other_player|
        print "#{(9 - player.losses[other_player.name].to_s.length) * " "}#{player.losses[other_player.name]} "
      end
      puts ""
    end
    puts "Thanks for playing Hangman, see you next time! \n\n\n\n\n\n\n\n\n"
    exit
  end

  def default_setup_round
    if players.length == 2
      guesser = round.checker
      checker = round.guesser
      prev_round_max_wrong_guesses = round.max_wrong_guesses
      self.round = Game.new(guesser, checker, prev_round_max_wrong_guesses)
    else
      guesser = players.values.sample
      1.times do
        checker = players.values.sample
        redo if guesser == checker
      end
      prev_round_max_wrong_guesses = round.max_wrong_guesses
      puts "Alrighty then, it'll be #{guesser.name} guessing #{checker.name}'s secret word! "
      self.round = Game.new(guesser, checker, prev_round_max_wrong_guesses)
    end
    self.default_setup = false
  end

  def setup_round
    checker = nil
    print "\nSo who's got the secret word this round? "
    until checker != nil
      checker = @players[gets.chomp]
      print "Huh? " if checker == nil
    end
    guesser = nil
    if players.length == 2
      players.each { |name, player| guesser = player if player != checker }
    else
      print "And who'll be guessing it? "
      until guesser != nil
        guesser = players[gets.chomp]
        print "Hm? " if checker == nil
      end
    end
    self.round = Game.new(guesser, checker, set_max_wrong_guesses)
  end

  def set_max_wrong_guesses
    print "How many wrong guesses allowed this round? "
    max_wrong_guesses = gets.chomp.to_i

    until max_wrong_guesses > 0
      print "Huh? "
      max_wrong_guesses = gets.chomp.to_i
    end

    if max_wrong_guesses > 25
      max_wrong_guesses = 25
      puts "\nErrr... well it's not really possible to guess wrong"
      puts "more than 25 times, so we'll just say 25 then. \n\n"
    end

    max_wrong_guesses
  end

  def setup
    system("clear")
    puts "\n\nWelcome to HANGMAN!\n\n"
  end

  def collect_players
    while true
      get_player
      if players.length >= 2
        print "\nAny more players? (y/n) "
        answer = gets.downcase.chomp[0]
        break if answer != 'y'
      end
    end
  end

  def get_player
    if players.length == 0
      print "Are you a computer or human? "
    elsif players.length == 1
      print "\nAnd how about you, other player - computer or human? "
    else
      print "\nOkay, player #{players.count + 1}, then. Are you computer or human? "
    end
    input = gets.chomp.downcase
    get_player_name(input)
  end

  def get_player_name(input)
    if input == "human"
      print "What is your human name? "
      name = gets.chomp
      self.players[name] = HumanPlayer.new(name, false)
    elsif input == "computer"
      print "What are you known by? "
      name = gets.chomp
      self.players[name] = ComputerPlayer.new(name, :hard) #for now, always super_computer_level
    else
      puts "Er, only humans and computers allowed... "
      until input == "human" || input == "computer"
        print "So which are you? "
        input = gets.chomp.downcase
      end
      get_player_name(input)
    end
  end

end

if __FILE__ == $PROGRAM_NAME
  hangman = Hangman.new.play
end

#hangman = Hangman.new.play

binding.pry
