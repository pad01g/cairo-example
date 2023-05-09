// $ name=scope-attributes ; cairo-compile $name.cairo --output $name.json && cairo-run --program=$name.json --print_output --layout=small --print_memory --print_info --trace_file=$name-trace.bin --memory_file=$name-memory.bin --relocate_prints --debug_error 
// Got an error:
// Error message: x must not be zero. Got x=0.
// scope-attributes.cairo:5:21: Error at pc=0:7:
// Unknown value for memory cell at address 1:10.
//         return (res=1 / x);
//                     ^***^
// Cairo traceback (most recent call last):
// scope-attributes.cairo:19:5: (pc=0:17)
//     assert_not_equal(1, 1);
//     ^********************^
// Error message: a and b must be distinct.
// scope-attributes.cairo:12:9: (pc=0:10)
//         inverse(diff);
//         ^***********^
// Error: Run must be ended before calling read_return_values.

from starkware.cairo.common.math import assert_not_zero

func inverse(x) -> (res: felt) {
    with_attr error_message("x must not be zero. Got x={x}.") {
        return (res=1 / x);
    }
}

func assert_not_equal(a, b) {
    let diff = a - b;
    with_attr error_message("a and b must be distinct.") {
        inverse(diff);
    }
    return ();
}

func main() {
    // Call pow(2, 5).
    assert_not_equal(1, 1);
    ret;
}
