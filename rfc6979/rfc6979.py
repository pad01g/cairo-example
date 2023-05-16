from secp256k1 import PrivateKey, PublicKey
import pprint, json

key = '31a84594060e103f5a63eb742bd46cf5f5900d8406e2726dedfc61c7cf43ebad'
msg = '9e5755ec2f328cc8635a55415d0e9a09c2b6f2c9b0343c945fbbfe08247a4cbe'
# 30 44 02 20 132382ca59240c2e14ee7ff61d90fc63276325f4cbe8169fc53ade4a407c2fc8 02 20 4d86fbe3bde6975dd5a91fdc95ad6544dcdf0dab206f02224ce7e2b151bd82ab
sig = '30440220132382ca59240c2e14ee7ff61d90fc63276325f4cbe8169fc53ade4a407c2fc802204d86fbe3bde6975dd5a91fdc95ad6544dcdf0dab206f02224ce7e2b151bd82ab'

msg_ser = bytes(bytearray.fromhex(msg))
privkey = PrivateKey(bytes(bytearray.fromhex(key)), raw=True)
privkey_ser = privkey.private_key
pubkey_ser = privkey.pubkey.serialize(compressed=False)
sig_check = privkey.ecdsa_sign(bytes(bytearray.fromhex(msg)), raw=True)
sig_ser = privkey.ecdsa_serialize(sig_check)

assert sig_ser == bytes(bytearray.fromhex(sig))

# pubkey has 65 byte length in DER encoding
# signature has 70 bytes length in DER encoding https://crypto.stackexchange.com/questions/57731/ecdsa-signature-rs-to-asn1-der-encoding-question
print(len(privkey_ser), len(pubkey_ser), len(sig_ser), len(msg_ser))

pprint.pprint({
    "msg_1": "0x" + msg_ser[0:16].hex(),
    "msg_2": "0x" + msg_ser[16:32].hex(),
    "privkey_1": "0x" + privkey_ser[0:16].hex(),
    "privkey_2": "0x" + privkey_ser[16:32].hex(),
    "pubkey_x_1": "0x" + pubkey_ser[0+1:16+1].hex(),
    "pubkey_x_2": "0x" + pubkey_ser[16+1:32+1].hex(),
    "pubkey_y_1": "0x" + pubkey_ser[32+1:48+1].hex(),
    "pubkey_y_2": "0x" + pubkey_ser[48+1:64+1].hex(),
    "sig_r_1": "0x" + sig_ser[0+4:16+4].hex(),
    "sig_r_2": "0x" + sig_ser[16+4:32+4].hex(),
    "sig_s_1": "0x" + sig_ser[32+6:48+6].hex(),
    "sig_s_2": "0x" + sig_ser[48+6:64+6].hex(),
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

# Write the data (public keys and votes) to a JSON file.
input_data = {
    'd_high': "0x" + privkey_ser[0:16].hex(),
    'd_low': "0x" + privkey_ser[16:32].hex(),
}

with open('rfc6979-input.json', 'w') as f:
    json.dump(input_data, f, indent=4)
    f.write('\n')