%builtins output range_check
from starkware.cairo.common.math import assert_nn_le
from starkware.cairo.common.serialize import serialize_word
from starkware.cairo.common.registers import get_fp_and_pc

struct KeyValue {
    key: felt,
    value: felt,
}

// Returns the value associated with the given key.
func get_value_by_key{range_check_ptr}(
    list: KeyValue*, size, key
) -> (value: felt) {
    alloc_locals;
    local idx;
    %{
        # Populate idx using a hint.
        ENTRY_SIZE = ids.KeyValue.SIZE
        KEY_OFFSET = ids.KeyValue.key
        VALUE_OFFSET = ids.KeyValue.value
        for i in range(ids.size):
            addr = ids.list.address_ + ENTRY_SIZE * i + \
                KEY_OFFSET
            if memory[addr] == ids.key:
                ids.idx = i
                break
        else:
            raise Exception(
                f'Key {ids.key} was not found in the list.')
    %}

    // Verify that we have the correct key.
    let item: KeyValue = list[idx];
    assert item.key = key;

    // Verify that the index is in range (0 <= idx <= size - 1).
    assert_nn_le(a=idx, b=size - 1);

    // Return the corresponding value.
    return (value=item.value);
}

func main{output_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    const ARRAY_SIZE = 5;
    local key_value_tuple: (
        KeyValue, KeyValue, KeyValue, KeyValue, KeyValue
    ) = (
        KeyValue(key=0, value=0),
        KeyValue(key=1, value=1),
        KeyValue(key=2, value=4),
        KeyValue(key=3, value=9),
        KeyValue(key=4, value=16),
    );

    let (__fp__, _) = get_fp_and_pc();
    let (value) = get_value_by_key(list=cast(&key_value_tuple, KeyValue*), size=ARRAY_SIZE, key=3);
    serialize_word(value);

    return ();
}