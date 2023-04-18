%builtins output range_check
from starkware.cairo.common.registers import get_fp_and_pc
from starkware.cairo.common.dict_access import DictAccess
from starkware.cairo.common.squash_dict import squash_dict
from starkware.cairo.common.serialize import serialize_word
from starkware.cairo.common.alloc import alloc

struct KeyValue {
    key: felt,
    value: felt,
}


// Builds a DictAccess list for the computation of the cumulative
// sum for each key.
func build_dict(list: KeyValue*, size, dict: DictAccess*) -> (
    dict:  DictAccess*
) {
    alloc_locals;
    local cumulative_sum_so_far;

    if (size == 0) {
        return (dict=dict);
    }

    %{
        # Populate ids.dict.prev_value using cumulative_sums...
        # Add list.value to cumulative_sums[list.key]...
        if ids.list.key in cumulative_sums.keys():
            ids.cumulative_sum_so_far = cumulative_sums[ids.list.key]
            cumulative_sums[ids.list.key] += ids.list.value;
        else:
            ids.cumulative_sum_so_far = 0
            cumulative_sums[ids.list.key] = ids.list.value;
    %}
    // Copy list.key to dict.key...
    // Verify that dict.new_value = dict.prev_value + list.value...
    // Call recursively to build_dict()...
    assert dict.key = list.key;
    assert dict.prev_value = cumulative_sum_so_far;
    assert dict.new_value = dict.prev_value + list.value;

    return build_dict(
        list = list + KeyValue.SIZE,
        size = size - 1,
        dict = dict + DictAccess.SIZE
    );
}

// Verifies that the initial values were 0, and writes the final
// values to result.
func verify_and_output_squashed_dict{output_ptr: felt*}(
    squashed_dict: DictAccess*,
    squashed_dict_end: DictAccess*,
    result: KeyValue*,
) -> (result:  KeyValue*) {
    tempvar diff = squashed_dict_end - squashed_dict;
    if (diff == 0) {
        return (result=result);
    }

    // Verify prev_value is 0...
    // Copy key to result.key...
    // Copy new_value to result.value...
    // Call recursively to verify_and_output_squashed_dict...
    assert result.key = squashed_dict.key;
    assert result.value = squashed_dict.new_value;
    assert squashed_dict.prev_value = 0;

    serialize_word(result.key);
    serialize_word(result.value);

    return verify_and_output_squashed_dict(
        squashed_dict + DictAccess.SIZE,
        squashed_dict_end,
        result + KeyValue.SIZE
    );
}

// Given a list of KeyValue, sums the values, grouped by key,
// and returns a list of pairs (key, sum_of_values).
func sum_by_key{output_ptr: felt*, range_check_ptr}(list: KeyValue*, size) -> (
    result: KeyValue*, result_size: felt
) {
    alloc_locals;
    %{
        # Initialize cumulative_sums with an empty dictionary.
        # This variable will be used by ``build_dict`` to hold
        # the current sum for each key.
        cumulative_sums = {};
    %}
    // Allocate memory for dict, squashed_dict and res...
    // Call build_dict()...
    // Call squash_dict()...
    // Call verify_and_output_squashed_dict()...
    let (local dict_start: DictAccess*) = alloc();
    let (local squashed_dict: DictAccess*) = alloc();
    let (local result: KeyValue*) = alloc();
    local result_size;

    let (dict_end) = build_dict(list=list, size=size, dict=dict_start);

    let (squashed_dict_end: DictAccess*) = squash_dict(
        dict_accesses=dict_start,
        dict_accesses_end=dict_end,
        squashed_dict=squashed_dict,
    );

    %{
        ids.result_size = len(cumulative_sums);
    %}
    assert squashed_dict_end - squashed_dict = result_size *
        DictAccess.SIZE;

    verify_and_output_squashed_dict(
        squashed_dict=squashed_dict,
        squashed_dict_end=squashed_dict_end,
        result=result,    
    );

    return (
        result=result,
        result_size=result_size
    );
}

func main{output_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    const ARRAY_SIZE = 5;
    local key_value_tuple: (
        KeyValue, KeyValue, KeyValue, KeyValue, KeyValue
    ) = (
        KeyValue(key=3, value=5),
        KeyValue(key=1, value=10),
        KeyValue(key=3, value=1),
        KeyValue(key=3, value=8),
        KeyValue(key=1, value=20),
    );

    let (__fp__, _) = get_fp_and_pc();
    let (result: KeyValue*, result_size: felt) = sum_by_key(list=cast(&key_value_tuple, KeyValue*), size=ARRAY_SIZE);

    return ();
}