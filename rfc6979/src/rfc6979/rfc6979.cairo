%builtins pedersen range_check bitwise

from starkware.cairo.common.alloc import alloc
from crypto.secp256k1_ecdsa import verify_ecdsa_secp256k1
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_secp.bigint import BigInt3, uint256_to_bigint
from starkware.cairo.common.cairo_secp.ec import EcPoint, ec_add, ec_mul
from starkware.cairo.common.cairo_secp.signature import (
    validate_signature_entry,
    get_generator_point,
    // div_mod_n,
)
from starkware.cairo.common.cairo_builtins import (
    HashBuiltin,
    BitwiseBuiltin,
)
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.math import split_felt


// Convert a felt to a Uint256
//
func felt_to_uint256{range_check_ptr}(value) -> Uint256 {
    let (high, low) = split_felt(value);
    let value256 = Uint256(high, low);
    // let value256 = Uint256(low, high);
    return value256;
}

// (1) (R,S) verifies for Q and m
// (2) R = hmac-sha256(d,m) * G
// (3) Q = d * G
func main{
    pedersen_ptr: HashBuiltin*,
    range_check_ptr,
    bitwise_ptr: BitwiseBuiltin*,
}() {
    alloc_locals;

    // (1)
    // Uint256(lower 16 bytes, higher 16 bytes)
    let (x_as_bigint3) = uint256_to_bigint(Uint256(0x42c9a29bf31c931154eb331c21b6f6fd, 0x087602e71a82777a7a9c234b668a1dc9));
    let (y_as_bigint3) = uint256_to_bigint(Uint256(0xf46848d3adb535acf74ca9a2558d2026, 0x519fa81e6550cf453164c45a1e968ad7));

    let pt = EcPoint(x_as_bigint3, y_as_bigint3);

    let (r) = uint256_to_bigint( Uint256(0x492e341294025332d41a6cdd9fa01b1c, 0xf649260ca357bc6b3eceac8533f148c2) );
    let (s) = uint256_to_bigint( Uint256(0x34501a2fa2d2a499e43502e6493ac220, 0x60560681be0c75043cc27fb5ee753b46) );
    let msg_low = 0xc2b6f2c9b0343c945fbbfe08247a4cbe;
    let msg_high = 0x9e5755ec2f328cc8635a55415d0e9a09;
    let (z) = uint256_to_bigint( Uint256(msg_low, msg_high) );
    verify_ecdsa_secp256k1(pt, z, r, s);
    
    // prepare for (2) and (3)
    local d_low;
    local d_high;
    %{
        ids.d_low = int(program_input["d_low"], 16)
        ids.d_high = int(program_input["d_high"], 16)
    %}
    let (d) = uint256_to_bigint( Uint256(d_low, d_high) );
    let (gen_pt: EcPoint) = get_generator_point();

    // (2)
    let (message_hash) = hash2{hash_ptr=pedersen_ptr}(
        x=msg_high, y=msg_low
    );
    let (privatekey_hash) = hash2{hash_ptr=pedersen_ptr}(
        x=d_high, y=d_low
    );
    let (nonce) = hash2{hash_ptr=pedersen_ptr}(
        x=message_hash, y=privatekey_hash
    );

    // convert nonce to element as little endian
    let n_uint256 = felt_to_uint256(nonce);
    let (n) = uint256_to_bigint(n_uint256);

    %{
        print("nonce", ids.nonce)
        print("n", ids.n)
        print("n_uint256.low", ids.n_uint256.low)
        print("n_uint256.high", ids.n_uint256.high)
    %}

    with_attr error_message("Invalid nonce.") {
        let (gen_n: EcPoint) = ec_mul(gen_pt, n);
        %{
            print("r.d0", ids.r.d0)
            print("r.d1", ids.r.d1)
            print("r.d2", ids.r.d2)
            print("gen_n.x.d0", ids.gen_n.x.d0)
            print("gen_n.x.d1", ids.gen_n.x.d1)
            print("gen_n.x.d2", ids.gen_n.x.d2)
        %}
        assert r = gen_n.x;
    }

    // (3)
    with_attr error_message("Invalid key pair.") {
        let (gen_d: EcPoint) = ec_mul(gen_pt, d);
        assert pt.x = gen_d.x;
        // assert pt.y = gen_d.y;
    }

    return ();
}