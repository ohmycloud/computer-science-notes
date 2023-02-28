object PatternMatchingOnADTs extends App {
  object Location {
        opaque type Location = String
        def apply(value: String): Location = value
        extension(a: Location) def name: String = a
  }
  import Location._  
  enum MusicGenre {
      case HeavyMetal
      case Pop
      case HardRock
  }
  
  enum YearsActive {
      case StillActive(since: Int)
      case ActiveBetween(start: Int, end: Int)
  }
  
  import MusicGenre._
  import YearsActive._

  case class Artist(name: String, genre: MusicGenre, origin: Location, yearsActive: YearsActive)
  
  def activeLength(artist: Artist, currentYear: Int): Int = {
      artist.yearsActive match {
          case StillActive(since)        => currentYear - since
          case ActiveBetween(start, end) => end - start
      }
  }
  println(activeLength(Artist("Metallica", HeavyMetal, Location("U.S."), StillActive(1981)),2022))
}