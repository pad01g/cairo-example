// (cairo_venv) ubuntu@randd:~/randd/cairo-example/how-cairo-works/1-introduction-to-cairo$ name=continuous-memory-2 ; cairo-compile $name.cairo --output $name.json && cairo-run --program=$name.json --print_output --layout=small --print_memory --print_info --trace_file=poly_trace.bin --memory_file=poly_memory.bin --relocate_prints
// continuous-memory-2.cairo:3:11: Expected a constant offset in the range [-2^15, 2^15).
//     [ap + 10000000000] = 400;
//           ^*********^
// Preprocessed instruction:
// [ap + 10000000000] = 400


func main() {
    [ap] = 300;
    [ap + 10000000000] = 400;
    ret;
}