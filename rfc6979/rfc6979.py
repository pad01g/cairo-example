from secp256k1 import PrivateKey, PublicKey
from cffi import FFI  # noqa: E402
from starkware.crypto.signature.signature import pedersen_hash
import pprint, json, tempfile, sys

key = '31a84594060e103f5a63eb742bd46cf5f5900d8406e2726dedfc61c7cf43ebad'
msg = '9e5755ec2f328cc8635a55415d0e9a09c2b6f2c9b0343c945fbbfe08247a4cbe'
# 30 44 02 20 132382ca59240c2e14ee7ff61d90fc63276325f4cbe8169fc53ade4a407c2fc8 02 20 4d86fbe3bde6975dd5a91fdc95ad6544dcdf0dab206f02224ce7e2b151bd82ab
# sig = '30440220132382ca59240c2e14ee7ff61d90fc63276325f4cbe8169fc53ade4a407c2fc802204d86fbe3bde6975dd5a91fdc95ad6544dcdf0dab206f02224ce7e2b151bd82ab'

# <!-- custom nonce function
# https://github.com/rustyrussell/secp256k1-py/blob/5bad581d959d722bf6c2df5eaa996fd4c24096aa/tests/test_custom_nonce.py#L51
ffi = FFI()
ffi.cdef('static int nonce_function_rand(unsigned char *nonce32,'
         'const unsigned char *msg32,const unsigned char *key32,'
         'const unsigned char *algo16,void *data,unsigned int attempt);')
# simple passthrough function
ffi.set_source("_noncefunc",
               """
static int nonce_function_rand(unsigned char *nonce32,
const unsigned char *msg32,
const unsigned char *key32,
const unsigned char *algo16,
void *data,
unsigned int attempt)
{
memcpy(nonce32,data,32);
return 1;
}
               """)

with tempfile.TemporaryDirectory() as build_temp:
    ffi.compile(tmpdir=build_temp)

    # Make sure we can find our nonce.
    sys.path.append(build_temp)

    import _noncefunc  # noqa: E402
    from _noncefunc import ffi  # noqa: E402

nf = ffi.addressof(_noncefunc.lib, "nonce_function_rand")
# ndata is pedersen_hash(msg, private-key)
nonce = pedersen_hash(
    pedersen_hash(
        int("0x"+msg[0:32], 16),
        int("0x"+msg[32:64], 16)
    ),
    pedersen_hash(
        int("0x"+key[0:32], 16),
        int("0x"+key[32:64], 16)
    )
)
nonce_bytes = nonce.to_bytes(32, 'big')
print("nonce", nonce_bytes.hex())
ndata = ffi.new("char [32]", nonce_bytes )
# custom nonce function -->

msg_ser = bytes(bytearray.fromhex(msg))
privkey = PrivateKey(bytes(bytearray.fromhex(key)), raw=True)
privkey_ser = privkey.private_key
pubkey_ser = privkey.pubkey.serialize(compressed=False)
sig_check = privkey.ecdsa_sign(bytes(bytearray.fromhex(msg)), raw=True, custom_nonce=(nf, ndata))
sig_ser = privkey.ecdsa_serialize(sig_check)

# assert sig_ser == bytes(bytearray.fromhex(sig))
assert True == privkey.pubkey.ecdsa_verify(msg_ser, sig_check, raw=True)

# pubkey has 65 byte length in DER encoding
# signature has 70 bytes length in DER encoding https://crypto.stackexchange.com/questions/57731/ecdsa-signature-rs-to-asn1-der-encoding-question
print(len(privkey_ser), len(pubkey_ser), len(sig_ser), sig_ser.hex(), len(msg_ser))

pprint.pprint({
    "msg_1": "0x" + msg_ser[0:16].hex(),
    "msg_2": "0x" + msg_ser[16:32].hex(),
    "privkey_1": "0x" + privkey_ser[0:16].hex(),
    "privkey_2": "0x" + privkey_ser[16:32].hex(),
    "pubkey_x_1": "0x" + pubkey_ser[0+1:16+1].hex(),
    "pubkey_x_2": "0x" + pubkey_ser[16+1:32+1].hex(),
    "pubkey_y_1": "0x" + pubkey_ser[32+1:48+1].hex(),
    "pubkey_y_2": "0x" + pubkey_ser[48+1:64+1].hex(),
    "sig_r_1": "0x" + sig_ser[0+5:16+5].hex(),
    "sig_r_2": "0x" + sig_ser[16+5:32+5].hex(),
    "sig_s_1": "0x" + sig_ser[32+7:48+7].hex(),
    "sig_s_2": "0x" + sig_ser[48+7:64+7].hex(),
    # "sig_r_1": "0x" + sig_ser[0+4:16+4].hex(),
    # "sig_r_2": "0x" + sig_ser[16+4:32+4].hex(),
    # "sig_s_1": "0x" + sig_ser[32+6:48+6].hex(),
    # "sig_s_2": "0x" + sig_ser[48+6:64+6].hex(),

})

# {'msg_1': '0x9e5755ec2f328cc8635a55415d0e9a09',
#  'msg_2': '0xc2b6f2c9b0343c945fbbfe08247a4cbe',
#  'privkey_1': '0x31a84594060e103f5a63eb742bd46cf5',
#  'privkey_2': '0xf5900d8406e2726dedfc61c7cf43ebad',
#  'pubkey_x_1': '0x087602e71a82777a7a9c234b668a1dc9',
#  'pubkey_x_2': '0x42c9a29bf31c931154eb331c21b6f6fd',
#  'pubkey_y_1': '0x519fa81e6550cf453164c45a1e968ad7',
#  'pubkey_y_2': '0xf46848d3adb535acf74ca9a2558d2026',
#  'sig_r_1': '0x132382ca59240c2e14ee7ff61d90fc63',
#  'sig_r_2': '0x276325f4cbe8169fc53ade4a407c2fc8',
#  'sig_s_1': '0x4d86fbe3bde6975dd5a91fdc95ad6544',
#  'sig_s_2': '0xdcdf0dab206f02224ce7e2b151bd82ab'}

# let's calculate expected value of nonce * G


# Write the data (public keys and votes) to a JSON file.
input_data = {
    'd_high': "0x" + privkey_ser[0:16].hex(),
    'd_low': "0x" + privkey_ser[16:32].hex(),
}

with open('rfc6979-input.json', 'w') as f:
    json.dump(input_data, f, indent=4)
    f.write('\n')