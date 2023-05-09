%builtins output pedersen

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash import hash2

func hash_chain(pedersen_ptr: HashBuiltin*, x, y, z) -> (pedersen_ptr: HashBuiltin*, hash: felt) {
    alloc_locals;
    local xy;
    local xyz;

    let hash = pedersen_ptr;
    // Invoke the hash function.
    hash.x = x;
    hash.y = y;
    xy = hash.result;

    let hash2 = pedersen_ptr + HashBuiltin.SIZE;

    // Invoke the hash function.
    hash2.x = xy;
    hash2.y = z;

    xyz = hash2.result;
    
    return (pedersen_ptr = hash2 + HashBuiltin.SIZE, hash = xyz);
}

// Implicit arguments: addresses of the output and pedersen
// builtins.
func main{output_ptr, pedersen_ptr: HashBuiltin*}() {
    // The following line implicitly updates the pedersen_ptr
    // reference to pedersen_ptr + 3.
    let (pedersen_ptr, hash) = hash_chain(pedersen_ptr, 1, 2, 3);
    assert [output_ptr] = hash;

    // Manually update the output builtin pointer.
    let output_ptr = output_ptr + 1;

    // output_ptr and pedersen_ptr will be implicitly returned.
    return ();
}