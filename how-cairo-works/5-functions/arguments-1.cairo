// (cairo_venv) ubuntu@randd:~/randd/cairo-example/how-cairo-works/5-functions$ name=arguments-1 ; cairo-compile $name.cairo --output $name.json && cairo-run --program=$name.json --print_output --layout=small --print_memory --print_info --trace_file=$name-trace.bin --memory_file=$name-memory.bin --relocate_prints --debug_error 
// arguments-1.cairo:4:5: Member 'x' does not appear in definition of struct '__main__.foo.Args'.
//     args.x = 4, ap++;
//     ^****^
// (cairo_venv) ubuntu@randd:~/randd/cairo-example/how-cairo-works/5-functions$ name=arguments-1 ; cairo-compile $name.cairo --output $name.json && cairo-run --program=$name.json --print_output --layout=small --print_memory --print_info --trace_file=$name-trace.bin --memory_file=$name-memory.bin --relocate_prints --debug_error 
// arguments-1.cairo:5:5: Member 'y' does not appear in definition of struct '__main__.foo.Args'.
//     args.y = 5, ap++;
//     ^****^
// (cairo_venv) ubuntu@randd:~/randd/cairo-example/how-cairo-works/5-functions$ name=arguments-1 ; cairo-compile $name.cairo --output $name.json && cairo-run --program=$name.json --print_output --layout=small --print_memory --print_info --trace_file=$name-trace.bin --memory_file=$name-memory.bin --relocate_prints --debug_error 
// arguments-1.cairo:8:5: Static assert failed: ap + 1 != ap.
//     static_assert args + foo.Args.SIZE == ap;
//     ^***************************************^


func main() {

    let args = cast(ap, foo.Args*);
    args.x = 4, ap++;
    args.y = 5, ap++;
    // Check that ap was advanced the correct number of times
    // (this will ensure arguments were not forgotten).
    static_assert args + foo.Args.SIZE == ap;
    let foo_ret = call foo;

    [ap] = foo_ret.z + foo_ret.w, ap++;
    ret;
}

func foo(x, y) -> (z: felt, w: felt) {
    [ap] = x + y, ap++;  // z.
    [ap] = x * y, ap++;  // w.
    ret;
}

