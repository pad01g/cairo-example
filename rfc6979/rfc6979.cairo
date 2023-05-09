%builtins output pedersen range_check ecdsa
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import (
    HashBuiltin,
    SignatureBuiltin,
)
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.signature import (
    verify_ecdsa_signature,
)

// (1) (R,S) verifies for Q and m
// (2) R = hmac-sha256(d,m) * G
// (3) Q = d * G
func main{
    output_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr,
    ecdsa_ptr: SignatureBuiltin*,
}() {
    alloc_locals;

    local m;
    local private_key;
    local pub_key;
    local r;
    local s;
    %{
        ids.m = len(program_input['m'])
        ids.private_key = len(program_input['private_key'])
        ids.pub_key = len(program_input['pub_key'])
        ids.r = len(program_input['r'])
        ids.s = len(program_input['s'])
    %}

    // (1)
    verify_ecdsa_signature(
        message=m,
        public_key=pub_key,
        signature_r=r,
        signature_s=s,
    );
    
    // (2)
    // (3)

    return ();
}