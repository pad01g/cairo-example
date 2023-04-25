func main() {
    alloc_locals;
    // x is a list of lists.
    local x: felt**;
    %{ ids.x = segments.gen_arg([[1, 2], [3, 4]]) %}
    assert [[x]] = 1;
    assert [[x] + 1] = 2;
    assert [[x + 1]] = 3;
    assert [[x + 1] + 1] = 4;
    return ();
}

