/*
  Requirement: Ranking words

- The score of a given word is calculated by giving
  one point for each letter that is not an 'a'.
- For a given list of words, return a sorted list
  that starts with the highest-scoring word.
*/

object WordRank extends App {
    def score(word: String): Int = {
        word.replaceAll("a", "").length
    }

    def scoreWithBonus(word: String): Int = {
        val base = score(word)
        if (word.contains("c")) base + 5
        else base
    }
    
    def rankedWords(wordScore: String => Int, words: List[String]): List[String] = {
        words.sortBy(wordScore).reverse
    }

    def wordScores(wordScore: String => Int,
                   words: List[String]): List[Int] = {
        words.map(wordScore)
    }

    def highScoringWords(wordScore: String => Int, 
                         words: List[String]): List[String] = {
        words.filter(x => wordScore(x) > 1)
    }

    val languages = List("haskell", "rust", "scala", "java", "ada")
    println( rankedWords(score, languages) )
    println( rankedWords(scoreWithBonus, languages) )
    println( highScoringWords(score, languages))
}