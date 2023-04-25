import json

from starkware.crypto.signature.signature import pedersen_hash, sign

POLL_ID = 10018

input_data = json.load(open('voting-system-input-2.json'))
input_data['public_keys'][3] = '0x0'
input_data['public_keys'][5] = '0x0'
input_data['public_keys'][6] = '0x0'
input_data['public_keys'][8] = '0x0'
input_data['votes'] = []

# Generate a "yes" vote for voter 6.
voter_ids = [0, 1, 2, 4, 7, 9]
for voter_id in voter_ids:
    priv_key = 123456 * voter_id + 654321
    vote = 1
    r, s = sign(
        msg_hash=pedersen_hash(POLL_ID, vote),
        priv_key=priv_key,
    )
    input_data['votes'].append({
        'voter_id': voter_id,
        'vote': vote,
        'r': hex(r),
        's': hex(s),
    })

with open('voting-system-input-3.json', 'w') as f:
    json.dump(input_data, f, indent=4)
    f.write('\n')