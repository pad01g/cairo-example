%builtins range_check bitwise

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
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin

// (1) (R,S) verifies for Q and m
// (2) R = hmac-sha256(d,m) * G
// (3) Q = d * G
func main{
    range_check_ptr,
    bitwise_ptr: BitwiseBuiltin*,
}() {
    alloc_locals;

    // (1)
    // Uint256(lower 16 bytes, higher 16 bytes)
    let (x_as_bigint3) = uint256_to_bigint(Uint256(0x42c9a29bf31c931154eb331c21b6f6fd, 0x087602e71a82777a7a9c234b668a1dc9));
    let (y_as_bigint3) = uint256_to_bigint(Uint256(0xf46848d3adb535acf74ca9a2558d2026, 0x519fa81e6550cf453164c45a1e968ad7));

    let pt = EcPoint(x_as_bigint3, y_as_bigint3);

    let (r) = uint256_to_bigint( Uint256(0x276325f4cbe8169fc53ade4a407c2fc8, 0x132382ca59240c2e14ee7ff61d90fc63) );
    let (s) = uint256_to_bigint( Uint256(0xdcdf0dab206f02224ce7e2b151bd82ab, 0x4d86fbe3bde6975dd5a91fdc95ad6544) );
    let (z) = uint256_to_bigint( Uint256(0xc2b6f2c9b0343c945fbbfe08247a4cbe, 0x9e5755ec2f328cc8635a55415d0e9a09) );
    verify_ecdsa_secp256k1(pt, z, r, s);
    
    local d_low;
    local d_high;
    %{
        ids.d_low = int(program_input["d_low"], 16)
        ids.d_high = int(program_input["d_high"], 16)
    %}
    let (d) = uint256_to_bigint( Uint256(d_low, d_high) );

    // (2)


    // (3)
    let (gen_pt: EcPoint) = get_generator_point();
    with_attr error_message("Invalid key pair.") {
        let (gen_d: EcPoint) = ec_mul(gen_pt, d);
        assert pt.x = gen_d.x;
        // assert pt.y = gen_d.y;
    }

    return ();
}