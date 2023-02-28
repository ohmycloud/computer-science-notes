sub MAIN() {
    sub larger-than(List $numbers --> Callable) {
        return -> \x { $numbers.grep: * > x }
    }

    sub divisible-by(List $numbers --> Callable) {
        return -> \x { $numbers.grep: * % x == 0 }
    }

    sub shorter-than(List $strings --> Callable) {
        return -> \x { $strings.grep: *.chars < x }
    }

    sub more-than(List $strings --> Callable) {
        return -> \x { $strings.grep: *.comb('s').elems > x }
    }

    my $input = List(5, 1, 2, 4, 0, 15);
    my $strings = List("scala", "ada");
    my $larger-than-function = larger-than($input);
    my $divisible-by-function = divisible-by($input);
    my $shorter-than-function = shorter-than($strings);
    my $more-than-function = more-than($strings);

    say $larger-than-function(4);
    say $larger-than-function(1);
    say $divisible-by-function(5);
    say $divisible-by-function(2);
    say $shorter-than-function(5);
    say $shorter-than-function(7);
    say $more-than-function(2);
    say $more-than-function(0);
}