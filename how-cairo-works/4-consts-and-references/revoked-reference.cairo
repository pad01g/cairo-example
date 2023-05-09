//  the compiler may not be able to compute the change of ap

func main() {
    let x = [ap];
    [ap] = 1, ap++;
    [ap] = 2, ap++;

    [ap] = x, ap++;
    jmp rel -1;  // Jump to the previous instruction.
}
