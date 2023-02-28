object FunctionReturnAnotherFunction extends App {
    def largerThan(numbers: List[Int]): Int => List[Int] = {
        threshold => numbers.filter(x => x > threshold)
    }

    def divisibleBy(numbers: List[Int]): Int => List[Int] = {
        threshold => numbers.filter(x => x % threshold == 0)
    }

    def shorterThan(strings: List[String]): Int => List[String] = {
        threshold => strings.filter(x => x.length < threshold)
    }

    def moreThan(strings: List[String]): Int => List[String] = {
        ???
    }

    val input = List(5, 1, 2, 4, 0, 15)
    val stringInput = List("scala", "ada")
    val largerThanFunction = largerThan(input)
    val divisibleByFunction = divisibleBy(input)
    val shorterThanFunction = shorterThan(stringInput)
    println(largerThanFunction(4))
    println(largerThanFunction(1))
    println(divisibleByFunction(5))
    println(divisibleByFunction(2))
    println(shorterThanFunction(4))
    println(shorterThanFunction(7))
}
