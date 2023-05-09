func main() {
    call foo;
    call foo;
    call foo;

    ret;
}

func foo() {
    [ap] = 1000, ap++;
    ret;
}