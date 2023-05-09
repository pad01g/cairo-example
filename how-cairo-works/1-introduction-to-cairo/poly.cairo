func main() {
    // [fp] = 100;
    [ap] = 100, ap++;
    // << Your code here >>
    [fp+1] = [fp] + 23, ap++;
    [fp+2] = [fp+1] * [fp], ap++;
    [fp+3] = [fp+2] + 45, ap++;
    [fp+4] = [fp+3] * [fp], ap++;
    [fp+5] = [fp+4] + 67, ap++;
    // now, [ap] = [original_ap + 6] = [fp+6]
    // hence, [ap-1] = [fp+5]

    ret;
}

