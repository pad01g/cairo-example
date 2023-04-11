%builtins output

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.serialize import serialize_word

func array_prod(arr: felt*, size) -> felt {
    if (size == 0) {
        return 1;
    }

    // size is not zero.
    // taken only even elements 
    let prod_of_rest = array_prod(arr=arr + 2, size=size - 2);
    return arr[0] * prod_of_rest;
}

func main{output_ptr: felt*}() {
    const ARRAY_SIZE = 4;

    // Allocate an array.
    let (ptr) = alloc();

    // Populate some values in the array.
    assert [ptr] = 9;
    assert [ptr + 1] = 16;
    assert [ptr + 2] = 25;
    assert [ptr + 3] = 4;

    // Call array_prod to compute the product of the elements.
    let prod = array_prod(arr=ptr, size=ARRAY_SIZE);

    // Write the prod to the program output.
    serialize_word(prod);

    return ();
}
