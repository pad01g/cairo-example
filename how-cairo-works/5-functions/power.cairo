
func main() {
    // Call pow(2, 5).
    [ap] = 2, ap++;
    [ap] = 7, ap++;
    call pow;

    // Make sure the 2**7 is 128.
    [ap - 1] = 128;
    ret;
}

// inefficient algorithm, complexity ~ O(n)
func pow(x, n) -> (res: felt) {
    jmp pow_body if n != 0;
    [ap] = 1, ap++;
    ret;

    pow_body:
    [ap] = x, ap++;
    [ap] = n - 1, ap++;

    let pow_ret = call pow;
    
    [ap] = pow_ret.res * x, ap++;
    ret;
}

