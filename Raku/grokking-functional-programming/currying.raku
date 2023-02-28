sub MAIN() {
    sub score(Str $word --> Int) {
        return $word.subst('a', '', :g).chars;
    }

    sub high-scoring-words(Callable $word-score --> Callable) {
        return -> \higher-than {
            -> \words {
                words.grep: -> \word { $word-score(word) > higher-than }
            }
        }
    }

    my $words = List("ada", "haskell", "scala", "java", "rust");
    my $words2 = List("football", "f1", "hockey", "basketball");

    my $words-with-score-higher-than = high-scoring-words(&score);
    say $words-with-score-higher-than(0)($words);
    say $words-with-score-higher-than(1)($words);
    say $words-with-score-higher-than(0)($words2);
    say $words-with-score-higher-than(1)($words2);
}