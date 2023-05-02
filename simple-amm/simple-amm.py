import json

from starkware.crypto.signature.signature import (
    pedersen_hash, private_to_stark_key, sign)

# Set an identifier that will represent what we're signing for.
# message like "i am signing this for swap when id is ~"
POLL_ID = 10018
MAX_BALANCE = 2 ** 64 - 1

# Generate key pairs.
priv_keys = []
pub_keys = []

for i in range(10):
    priv_key = 123456 * i + 654321  # See "Safety note" below.
    priv_keys.append(priv_key)

    pub_key = private_to_stark_key(priv_key)
    pub_keys.append(pub_key)

transactions = []
for (account_id, token_a_amount, token_b_amount) in [(5, 10, 0), (0, 10, 0), (9, 0, 20)]:
    r, s = sign(
        msg_hash=pedersen_hash(POLL_ID, token_a_amount * MAX_BALANCE + token_b_amount),
        priv_key=priv_keys[account_id])
    transactions.append({
        'account_id': account_id,
        'token_a_amount': token_a_amount,
        'token_b_amount': token_b_amount,
        'r': hex(r),
        's': hex(s),
    })

# Write the data (public keys and transactions) to a JSON file.
input_data = {
    "token_a_balance": 100,
    "token_b_balance": 1000,
    # 'public_keys': list(map(hex, pub_keys)),
    'accounts': { k: {
            "public_key": v,
            "token_a_balance": (k**17 % 11 + 5)*10,
            "token_b_balance": (k**11 % 5 + 17)*10,
        } for (k, v) in enumerate(list(map(hex, pub_keys))) },
    'transactions': transactions,
}

with open('simple-amm-input.json', 'w') as f:
    json.dump(input_data, f, indent=4)
    f.write('\n')