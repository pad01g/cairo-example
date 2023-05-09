%builtins output pedersen

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash import hash2

func hash_chain{pedersen_ptr: HashBuiltin*}(x, y, z) -> (hash: felt) {
    alloc_locals;

    let (xy) = hash2{hash_ptr=pedersen_ptr}(x, y);
    let (xyz) = hash2{hash_ptr=pedersen_ptr}(xy, z);
        
    return (hash = xyz);
}

// Implicit arguments: addresses of the output and pedersen
// builtins.
func main{output_ptr, pedersen_ptr: HashBuiltin*}() {
    // The following line implicitly updates the pedersen_ptr
    // reference to pedersen_ptr + 3.
    let (hash) = hash_chain(1, 2, 3);
    assert [output_ptr] = hash;

    // Manually update the output builtin pointer.
    let output_ptr = output_ptr + 1;

    // output_ptr and pedersen_ptr will be implicitly returned.
    return ();
}