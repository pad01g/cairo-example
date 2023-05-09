%builtins output range_check
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.pow import pow

// this will fail, but it should work with right input.
func main{
    output_ptr: felt*,
    range_check_ptr,
}() {
    alloc_locals;

    local x1;
    local x2;
    %{
        ids.x1 = len(program_input['x1'])
        ids.x2 = len(program_input['x2'])
    %}

    let (pow1) = pow(x1,7);
    let (pow2) = pow(x1,7);

    assert pow1 + x1 + 18 = 0;
    assert pow2 + x2 + 18 = 0;
    assert_not_zero(x1 - x2);

    return ();
}