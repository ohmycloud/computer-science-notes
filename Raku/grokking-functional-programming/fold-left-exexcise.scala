object FoldLeftApp extends App {
    val input1 = List(5, 1, 2, 4, 100)
    val input2 = List("scala", "rust", "ada")
    val input3 = List("scala", "haskell", "rust", "ada")
    val input4 = List(5, 1, 2, 4, 15)

    def numberOfS(word: String): Int = {
        word.length - word.replaceAll("s", "").length
    }

    val res1 = input1.foldLeft(0)((sum, i) => sum + i)
    val res2 = input2.foldLeft(0)((sum, word) => sum + word.length)
    val res3 = input3.foldLeft(0)((sum, word) => sum + numberOfS(word))
    val res4 = input4.foldLeft(Int.MinValue)((max, i) => if (i > max) i else max)

    println(res1)
    println(res2)
    println(res3)
    println(res4)
}