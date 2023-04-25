func main() {
    alloc_locals;
    local x: felt*;
    %{ ids.x = segments.gen_arg([1, 2, 3]) %}
    assert [x] = 1;
    assert [x + 1] = 2;
    assert [x + 2] = 3;
    return ();
}

