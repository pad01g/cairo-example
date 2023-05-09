%builtins output pedersen

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.alloc import alloc

func hash_chain{pedersen_ptr: HashBuiltin*}(hash: felt, arr: felt*, size) -> felt {
    alloc_locals;
    if (size == 0){
        return hash;
    }
    if (size == 1){
        if (hash != 0){
            let (res) = hash2{hash_ptr=pedersen_ptr}(hash, arr[0]);
            return res;
        }else{
            return hash;
        }
    }else{
        if(hash == 0){
            let (res) = hash2{hash_ptr=pedersen_ptr}(arr[0], arr[1]);
            return hash_chain{pedersen_ptr=pedersen_ptr}(res, arr+2, size-2);
        }else{
            let (res) = hash2{hash_ptr=pedersen_ptr}(hash, arr[0]);
            return hash_chain{pedersen_ptr=pedersen_ptr}(res, arr+1, size-1);
        }    
    }
}

// Implicit arguments: addresses of the output and pedersen
// builtins.
func main{output_ptr, pedersen_ptr: HashBuiltin*}() {
    const ARRAY_SIZE = 4;

    // Allocate an array.
    let (ptr) = alloc();

    // Populate some values in the array.
    assert [ptr] = 1;
    assert [ptr + 1] = 2;
    assert [ptr + 2] = 3;
    assert [ptr + 3] = 4;

    // Call array_sum to compute the sum of the elements.
    let hash = hash_chain(hash = 0, arr=ptr, size=ARRAY_SIZE);

    assert [output_ptr] = hash;

    // Manually update the output builtin pointer.
    let output_ptr = output_ptr + 1;

    // output_ptr and pedersen_ptr will be implicitly returned.
    return ();
}