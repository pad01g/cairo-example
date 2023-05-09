func pow4(n) -> (m: felt) {

    jmp body if n != 0;
    [ap] = 0, ap++;
    ret;

    body:

    tempvar x = n * n;
    [ap] = x * x, ap++;
    ret;
}

func main() {
    pow4(n=5);
    ret;
}