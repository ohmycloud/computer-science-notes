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
)

sub score(Str $word --> Int) {
    return $word.subst("a", "", :g).chars;
}

sub score-with-bonus(Str $word --> Int) {
    my $base = score($word);
    return $word.contains("c") ?? $base + 5 !! $base
}

sub ranked-words(Callable $word-score, List $words --> Seq) {
    my &word-comparator = -> $w1, $w2 {
        $word-score($w2) cmp $word-score($w1)
    }

    return $words.sort(&word-comparator);
}

my $l = List('haskell', 'rust', 'scala', 'java', 'ada');
say ranked-words(&score, $l);
say ranked-words(&score-with-bonus, $l);