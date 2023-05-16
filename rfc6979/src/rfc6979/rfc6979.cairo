%builtins range_check bitwise

from starkware.cairo.common.alloc import alloc
from crypto.secp256k1_ecdsa import verify_ecdsa_secp256k1
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_secp.bigint import BigInt3, uint256_to_bigint
from starkware.cairo.common.cairo_secp.ec import EcPoint, ec_add, ec_mul
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

    let (x_as_bigint3) = uint256_to_bigint(Uint256(0xcfd5e9ad6175dec240d9f76e20b48b41, 0xbff381888b165f92dd33d09ff2cde2d4));
    let (y_as_bigint3) = uint256_to_bigint(Uint256(0x2e36f7acc2d711d8fb6fbbf53986b57f, 0xe4be2a8547d802dc42041b95be5934e3));

    let pt = EcPoint(x_as_bigint3, y_as_bigint3);

    let (r) = uint256_to_bigint( Uint256(0x770f9700f1ae6c77fee73f3ac9be1217, 0xeee3e6f50c576c07d7e4afc302c486b0) );
    let (s) = uint256_to_bigint( Uint256(0xcc3509cf420a4b46d3c5e24cda81f22, 0x541e10c21560da25ada4c259efe25609) );
    let (z) = uint256_to_bigint( Uint256(0xbfc5faa0e178a23ca66202c8c2a72277, 0xca1ad489ab60ea581e6c119cc39d94dd) );
    verify_ecdsa_secp256k1(pt, z, r, s);
    
    // (2)
    // (3)

    return ();
}