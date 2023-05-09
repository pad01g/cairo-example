func main() {
    [fp + 1] = 2, ap++;
    [fp] = 5201798304953761792, ap++;
    // infinite loop and infinite memory
    jmp rel -1;
    // infinite loop but finite memory
    //jmp rel -2;
}