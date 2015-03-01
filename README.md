# Gallows

## Story

This project arose from an AppAcademy polymorphism exercise: build a Hangman game which can be played by two players, agnostic to whether those players are humans or computers.

Soon I was inspired to support multiple levels of AI. For starters, I wrote an evil computer player that would avoid revealing letters whenever possible. That is, if you guessed "p", and the computer's secret word did contain a "p", but there was a remaining word that the current board could accommodate which did not include p, then the AI would sneakily switch its secret word to that word.

This evil AI of mine decided amongst those remaining words without 'p' by choosing the one with the least common letters. This directive was based on the assumption that the guessing player's best strategy is to choose the most commonly occurring remaining letter. Of course, while human guessers cannot come up with exact letter counts of the remaining words in the dictionary matching the current board, we figure that the amazingness that is the human brain does a pretty darn good job of estimating.

The problem with this AI's strategy, as I soon discovered, was that human guessers following this ideal strategy would still win quickly. In fact, they won even quicker! The reason was that it is sometimes more advantageous for the computer player to reveal a letter, even if it could choose not to. Perhaps it's best to illustrate by example:

* Suppose the guesser leads by guessing the most common letter in the English alphabet, "e". (Yes, I'm aware that "e" is not the most common letter for each word length, but let's not split hairs here.)
* The evil AI does not reveal an "e", eliminating all words from further consideration which have an "e". The human player now guesses the next most common letter, "a".
* Again, the evil AI does not reveal an "a". Do you see where this is going yet?
* By the end of turn 5, the human player has guessed all of the vowels, and none of them have been revealed. Therefore, only words whose vowel parts are entirely consisted by the letter "y" remain.
* The human player quickly wins from there.

I knew I needed to make the evil AI even smarter. What I eventually settled on was an AI which considered depth rather than breadth. That is, rather than consider the total rareness of letters across the dictionary at this moment to make its decision, my AI makes a tree and finds the deepest node possible on it. After all, the point of Hangman is to keep your opponent guessing as long as possible. And as it turns out, often the deepest node possible lays on a branch which involves revealing the letter the guesser has just guessed. In particular, my new improved AI reveals at least one "e" on the initial guess for many word lengths.

In other words, we make the assumption that the guesser is smart enough to estimate the frequency of letters in a dictionary subset, but not smart enough to neutralize the AI by also figuring out the guessing path depths and guessing letters in a manner designed to minimize it. In yet other words, we assume that the guesser does not realize that we are being evil and never really choosing a word; building a meta-AI that would detect a player's awareness of this and respond would be another scope of project altogether.

## Status

Anyway. I had this new improved evil AI working, however, since the it took several minutes to build its tree and respond, it consistently raised suspicion and ruined the effect for the player (of sucking tremendously at Hangman). Moreover, it was awful to wait.

So then I began to write the code I needed to build a database of every possible Hangman board state, and the response the evil AI should give. Thus, the Hangman game file might be suspiciously large holding all that data, but in this case I would much rather trade off the space for the time.

And to be exact, not *every* board state needs to be saved. Generally we can leave the AI to its default response - not revealing any letters, unless it is necessary to reveal a letter. We only need to add an entry to the database whenever it is actually advantageous for the AI to reveal a letter when it is unnecessary.

So that's where I'm at. I haven't yet been able to come up with a working strategy for building this database which doesn't take several years to run. I will solve this one day soon, though, then build a basic web interface for playing.
