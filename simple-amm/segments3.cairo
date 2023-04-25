from starkware.cairo.common.alloc import alloc

func main() {
    let (vec: felt*) = alloc();
    // Here, an address was already assigned to vec.
    %{ segments.write_arg(ids.vec, [1, 2, 3]) %}
    ap += 2;
    assert [vec] = 1;
    assert [vec + 1] = 2;
    assert [vec + 2] = 3;
    return ();
}