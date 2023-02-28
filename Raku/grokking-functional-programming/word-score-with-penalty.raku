#`(
    Requirement: Ranking words
    1. The score of a given word is calculated by giving
       one point for each letter that is not an 'a'.
    2. For a given list of words, return a sorted list that
       starts with the highest-scoring word.

    Requirement: Possibility of a bonus
    1. A bonus score of 5 needs to be added to
       the score if the word contains a 'c'.
    2. An old way of scoring (without the bonus)
       should still be supported in the code.

    New requirement: Possibility of a penalty
    1. A penalty score of 7 needs to be subtracted from the
       score if the word contains an 's'.
    2. Old ways of scoring (with and without the bonus) should
       still be supported in the code.
)

sub bonus(Str $word --> Int) {
    return $word.contains("c") ?? 5 !! 0;
}

sub penalty(Str $word --> Int) {
    return $word.contains("s") ?? 7 !! 0;
}

sub score(Str $word --> Int) {
    return $word.subst("a", "", :g).chars;
}

sub score-with-bonus(Str $word --> Int) {
    my $base = score($word);
    return $base + bonus($word);
}

sub score-with-penalty(Str $word --> Int) {
    my $bonus = score-with-bonus($word);
    return $bonus - penalty($word);
}

sub ranked-words(Callable $word-score, List $words --> Seq) {
    my &word-comparator = -> $w1, $w2 {
        $word-score($w2) cmp $word-score($w1)
    }

    return $words.sort(&word-comparator);
}

my $l = List('haskell', 'rust', 'scala', 'java', 'ada');

# Ranking the words with just a score function (no bonus and no penalty)
say ranked-words(&score, $l);

# Ranking the words with the score + bonus
say ranked-words(&score-with-bonus, $l);

# Ranking the words with the score + bonus - penalty
say ranked-words(&score-with-penalty, $l);