object CurryingApp extends App {
    def score(word: String): Int = {
        word.replaceAll("a", "").length
    }

    def highScoringWords(wordScore: String => Int): Int => List[String] => List[String] = {
        higherThan =>
          words =>
            words.filter(word => wordScore(word) > higherThan)
    }

    def cumulativeScore(wordScore: String => Int, 
                        words: List[String]): Int = {
        words.foldLeft(0)((total, word) => total + wordScore(word))
    }

    val words = List("ada", "haskell", "scala", "java", "rust")
    val words2 = List("football", "f1", "hockey", "basketball")

    val wordsWithScoreHigherThan = highScoringWords(score)
    println(wordsWithScoreHigherThan(0)(words))
    println(wordsWithScoreHigherThan(1)(words))
    println(wordsWithScoreHigherThan(0)(words2))
    println(wordsWithScoreHigherThan(1)(words2))
}