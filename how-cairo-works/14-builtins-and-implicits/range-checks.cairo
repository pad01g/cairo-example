%builtins range_check	
from starkware.cairo.common.math import assert_nn_le, assert_le, assert_lt

// 1
func foo1{range_check_ptr}(x){
    // Verify that the x is in range (0 <= x <= 1000).
    // assert_nn_le(a=x, b=1000);
    // assert_nn_le(a=x, b=1000);

    assert [range_check_ptr] = x; // 0 <= x < 2**128
    let range_check_ptr = range_check_ptr + 1;
    assert [range_check_ptr] = 1000 - x; // 0 <= 1000 - x < 2**128
    let range_check_ptr = range_check_ptr + 1;

    return ();
}

// 2
// Why isn’t checking that 0 <= 1000 - x < 2**128 enough?
// -> because x could be -1 = P - 1 and still pass the test.


// 3
func foo3{range_check_ptr}(x, y, z, w){

    // 0 <= x <= y
    assert [range_check_ptr] = x; // 0 <= x < 2**128
    let range_check_ptr = range_check_ptr + 1;
    assert [range_check_ptr] = y - x; // 0 <= y - x < 2**128
    let range_check_ptr = range_check_ptr + 1;

    // y <= z
    assert [range_check_ptr] = z - y; // 0 <= z - y < 2**128
    let range_check_ptr = range_check_ptr + 1;

    // z <= w
    assert [range_check_ptr] = w - z; // 0 <= w - z < 2**128
    let range_check_ptr = range_check_ptr + 1;

    // w <= 2**128
    assert [range_check_ptr] = w; // 0 <= w < 2**128
    let range_check_ptr = range_check_ptr + 1;

    return ();
}

// 4
// 0 <= x < 2**200
// x = a*(2**128) + b
// 0 <= a <= 2**71
// 0 <= b < 2**128
func foo4{range_check_ptr}(x){
    alloc_locals;
    local a;
    local b;
    %{
        ids.a = ids.x // (2**128)
        ids.b = ids.x % (2**128)
    %}
    assert x = a * (2**128) + b;
    
    // 0 <= a <= 2**71
    assert [range_check_ptr] = a; // 0 <= a < 2**128
    let range_check_ptr = range_check_ptr + 1;
    assert [range_check_ptr] = 2**71 - a; // 0 <= 2**71 - a < 2**128
    let range_check_ptr = range_check_ptr + 1;

    // 0 <= b < 2**128
    assert [range_check_ptr] = b; // 0 <= b < 2**128
    let range_check_ptr = range_check_ptr + 1;

    return ();
}

// divisibility testing
func divisibleBy2InRange{range_check_ptr}(x){
    alloc_locals;
    local a;

	// 0 <= x < 2**128
    assert [range_check_ptr] = x; // 0 <= x < 2**128
    let range_check_ptr = range_check_ptr + 1;

	%{
        ids.a = ids.x // 3
	%}

	assert x = a * 3;

	// 0 <= a <= 2**128 // 3
    assert [range_check_ptr] = a; // 0 <= a < 2**128
    let range_check_ptr = range_check_ptr + 1;
    assert [range_check_ptr] = 113427455640312821154458202477256070485 - a; // 0 <= (2**128 // 3) - a < 2**128
    let range_check_ptr = range_check_ptr + 1;

	return ();
}

// Integer division
// soundness note:
// assumption that |F| >= 2**128 is required because malicious prover can control q and r
// and therefore x = q * y + r may overflow if |F| < 2**128.
func div{range_check_ptr}(x, y) -> (q: felt, r: felt) {
    alloc_locals;
    local q;
    local r;
    %{ ids.q, ids.r = ids.x // ids.y, ids.x % ids.y %}

    // Check that 0 <= x < 2**64.
    [range_check_ptr] = x;
    assert [range_check_ptr + 1] = 2 ** 64 - 1 - x;

    // Check that 0 <= y < 2**64.
    [range_check_ptr + 2] = y;
    assert [range_check_ptr + 3] = 2 ** 64 - 1 - y;

    // Check that 0 <= q < 2**64.
    [range_check_ptr + 4] = q;
    assert [range_check_ptr + 5] = 2 ** 64 - 1 - q;

    // Check that 0 <= r < y.
    [range_check_ptr + 6] = r;
    assert [range_check_ptr + 7] = y - 1 - r;

    // Verify that x = q * y + r.
    assert x = q * y + r;

    let range_check_ptr = range_check_ptr + 8;
    return (q=q, r=r);
}

// Implicit arguments: addresses of the output and pedersen
// builtins.
func main{range_check_ptr}() {

    foo1(0);
    foo1(1);
    foo1(999);
    foo1(1000);
    // foo1(1001);

    foo3(0, 1, 2, 3);

    foo4(2**199);
    // foo4(2**200);

	divisibleBy2InRange(0);
	divisibleBy2InRange(3);
	divisibleBy2InRange(340282366920938463463374607431768211455);

	let (q1, r1) = div(15, 3);
	assert q1 = 5;
	assert r1 = 0;
	

    
    // output_ptr and pedersen_ptr will be implicitly returned.
    return ();
}

