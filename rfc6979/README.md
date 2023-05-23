# what is this?

Unsafe deterministic signature STARK proof (one round). It is unsafe PoC code resembling rfc6979.

# description

Nonce is calculated deterministically (see below). STARK proof is generated with private key input. Verifier can verify the proof without knowledge of private key.

```
(higher_m, lower_m) := message
(higher_d, lower_d) := private_key
H := pedersen_hash
nonce := H(H(higher_m, lower_m), H(higher_d, lower_d))
```

# memo

 - Output of `pedersen_hash` is 252 bits, instead of 256 bits of `hmac-sha256`. Thus, 4 bits of entropy is lost when generating hash for nonce.

 - It is unsafe scheme because `README` of `winterfell` library says it's not perfect zero knowledge.

https://github.com/facebook/winterfell

> The current implementation provides succinct proofs but NOT perfect zero-knowledge. This means that, in its current form, the library may not be suitable for use cases where proofs must not leak any info about secret inputs.

 - As this library potentially leaks knowledge about `private_key`, private key could be extracted when this scheme is used repeatedly.
 - `crypto` and `utils` are copied from zerosync project.


# run

```
$ python3 rfc6979.py
$ export name=rfc6979; cairo-compile src/$name/$name.cairo --output $name.json --cairo_path src && cairo-run --program=$name.json --print_output --layout=dynamic  --print_info --trace_file=$name-trace.bin --memory_file=$name-memory.bin  --debug_error  --program_input=$name-input.json
```

# see also

 - https://medium.com/blockstream/anti-exfil-stopping-key-exfiltration-589f02facc2e

 - https://eprint.iacr.org/2020/1057.pdf
