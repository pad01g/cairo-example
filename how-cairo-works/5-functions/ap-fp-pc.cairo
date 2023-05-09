func main() {

    [ap] = 1000, ap++;

    call foo;

    [ap] = 2000, ap++;

    call foo;

    [ap] = 3000, ap++;

    call foo;

    ret;
}

func foo() {
    // ap == fp at the start of function
    [ap+1] = [fp-2]; // old fp
    [ap+2] = [fp-1]; // return pc
    [ap] = [fp-3]; // old ap is fp-3, so use fp-4 maybe?

    ap += 3;

    ret;
}