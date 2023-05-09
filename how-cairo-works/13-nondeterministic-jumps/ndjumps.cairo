func div2(x) -> (res: felt) {
    // if you jump by memory, you only know that prover know some [ap] that can run either `even:` or `odd:`.
    // but you already know that the code will run `even:` or `odd:` anyway,
    // so this div2() does not guarantee anything.
    // if this is used in case where it is nontrivial to find [ap] that satisfies `even:` or `odd:`,
    // then this function may have meaning.

    %{ memory[ap] = ids.x % 2 %}
    jmp odd if [ap] != 0, ap++;

    even:
    // Case x % 2 == 0.
    [ap] = x / 2, ap++;
    ret;

    odd:
    // Case x % 2 == 1.
    [ap] = x - 1, ap++;
    [ap] = [ap - 1] / 2, ap++;
    ret;
}

func main() {
    alloc_locals;
    local ret99;
    local ret100;

    [ap] = 99, ap++;
    let ret99_tmp = call div2;
    assert ret99 = ret99_tmp.res;

    [ap] = 100, ap++;
    let ret100_tmp = call div2;
    assert ret100 = ret100_tmp.res;

    [ap] = ret99, ap++;
    [ap] = ret100, ap++;

    ret;
}