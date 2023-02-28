object PracticingCurrying extends App {
    def largerThan(n: Int)(i: Int): Boolean = i > n

    def divisibleBy(n: Int)(i: Int): Boolean = i % n == 0

    def shorterThan(n: Int)(s: String): Boolean = s.length < n

    def numberOfS(s: String): Int = s.length - s.replaceAll("s", "").length
    def moreThan(moreThan: Int)(s: String): Boolean = numberOfS(s) > moreThan

    val input = List(5, 1, 2, 4, 0)
    val input1 = List(5, 1, 2, 4, 15)
    val input2 = List("scala", "ada")
    val input3 = List("rust", "ada")
    println(input.filter(largerThan(4)))
    println(input1.filter(divisibleBy(5)))
    println(input2.filter(shorterThan(4)))
    println(input3.filter(moreThan(2)))
}