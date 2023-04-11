%builtins output range_check
from starkware.cairo.common.registers import get_fp_and_pc
from starkware.cairo.common.dict_access import DictAccess
from starkware.cairo.common.squash_dict import squash_dict
from starkware.cairo.common.serialize import serialize_word
from starkware.cairo.common.alloc import alloc

struct Location {
    row: felt,
    col: felt,
}

func verify_valid_location(loc: Location*) {
    // Check that row is in the range 0-3.
    tempvar row = loc.row;
    assert row * (row - 1) * (row - 2) * (row - 3) = 0;

    // Check that col is in the range 0-3.
    tempvar col = loc.col;
    assert col * (col - 1) * (col - 2) * (col - 3) = 0;

    return ();
}

func verify_adjacent_locations(
    loc0: Location*, loc1: Location*
) {
    alloc_locals;
    local row_diff = loc0.row - loc1.row;
    local col_diff = loc0.col - loc1.col;

    if (row_diff == 0) {
        // The row coordinate is the same. Make sure the
        // difference in col is 1 or -1.
        assert col_diff * col_diff = 1;
        return ();
    } else {
        // Verify the difference in row is 1 or -1.
        assert row_diff * row_diff = 1;
        // Verify that the col coordinate is the same.
        assert col_diff = 0;
        return ();
    }
}

func verify_location_list(loc_list: Location*, n_steps) {
    alloc_locals;

    // Always verify that the location is valid, even if
    // n_steps = 0 (remember that there is always one more
    // location than steps).
    verify_valid_location(loc=loc_list);

    if (n_steps == 0) {
        local row = loc_list.row;
        local col = loc_list.col;
        assert row = 3;
        assert col = 3;

        return ();
    }


    verify_adjacent_locations(
        loc0=loc_list, loc1=loc_list + Location.SIZE
    );

    // Call verify_location_list recursively.
    verify_location_list(
        loc_list=loc_list + Location.SIZE, n_steps=n_steps - 1
    );
    return ();
}

func build_dict(
    loc_list: Location*,
    tile_list: felt*,
    n_steps,
    dict: DictAccess*,
) -> (dict: DictAccess*) {
    if (n_steps == 0) {
        // When there are no more steps, just return the dict
        // pointer.
        return (dict=dict);
    }

    // Set the key to the current tile being moved.
    assert dict.key = [tile_list];

    // Its previous location should be where the empty tile is
    // going to be.
    let next_loc: Location* = loc_list + Location.SIZE;
    assert dict.prev_value = 4 * next_loc.row + next_loc.col;

    // Its next location should be where the empty tile is
    // now.
    assert dict.new_value = 4 * loc_list.row + loc_list.col;

    // Call build_dict recursively.
    return build_dict(
        loc_list=next_loc,
        tile_list=tile_list + 1,
        n_steps=n_steps - 1,
        dict=dict + DictAccess.SIZE,
    );
}

func finalize_state(dict: DictAccess*, idx) -> (
    dict: DictAccess*
) {
    if (idx == 0) {
        return (dict=dict);
    }

    // key: actual number of location
    // prev_value, new_value: encoded location of coordinate
    // for example, (2, 2) = 2*4 + 2 = 10
    //
    // index:
    //
    // 00 01 02 03
    // 04 05 06 07
    // 08 09 10 11
    // 12 13 14 15
    //
    // dict_key starts from 1:
    // 
    // 01 02 03 04
    // 05 06 07 08
    // 09 10 11 12
    // 13 14 15 ??
    // 
    // for example, if dict_key = 11,
    // then index is 10, which translates to (2, 2) in coordinate
    // 

    assert dict.key = idx;
    assert dict.prev_value = idx - 1;
    assert dict.new_value = idx - 1;

    // Call finalize_state recursively.
    return finalize_state(
        dict=dict + DictAccess.SIZE, idx=idx - 1
    );
}

func output_initial_values{output_ptr: felt*}(
    squashed_dict: DictAccess*, n
) {
    if (n == 0) {
        return ();
    }

    serialize_word(squashed_dict.prev_value);

    // Call output_initial_values recursively.
    return output_initial_values(
        squashed_dict=squashed_dict + DictAccess.SIZE, n=n - 1
    );
}

func check_solution{output_ptr: felt*, range_check_ptr}(
    loc_list: Location*, tile_list: felt*, n_steps
) {
    alloc_locals;

    // Start by verifying that loc_list is valid.
    verify_location_list(loc_list=loc_list, n_steps=n_steps);

    // Allocate memory for the dict and the squashed dict.
    let (local dict_start: DictAccess*) = alloc();
    let (local squashed_dict: DictAccess*) = alloc();

    let (dict_end) = build_dict(
        loc_list=loc_list,
        tile_list=tile_list,
        n_steps=n_steps,
        dict=dict_start,
    );

    let (dict_end) = finalize_state(dict=dict_end, idx=15);

    let (squashed_dict_end: DictAccess*) = squash_dict(
        dict_accesses=dict_start,
        dict_accesses_end=dict_end,
        squashed_dict=squashed_dict,
    );

    // Verify that the squashed dict has exactly 15 entries.
    // This will guarantee that all the values in the tile list
    // are in the range 1-15.
    assert squashed_dict_end - squashed_dict = 15 *
        DictAccess.SIZE;

    output_initial_values(squashed_dict=squashed_dict, n=15);

    // Output the initial location of the empty tile.
    serialize_word(4 * loc_list.row + loc_list.col);

    // Output the number of steps.
    serialize_word(n_steps);

    return ();
}

func main{output_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    local loc_tuple: (
        Location, Location, Location, Location, Location
    ) = (
        Location(row=0, col=2),
        Location(row=1, col=2),
        Location(row=1, col=3),
        Location(row=2, col=3),
        Location(row=3, col=3),
    );

    local tiles: (felt, felt, felt, felt) = (3, 7, 8, 12);

    // Get the value of the frame pointer register (fp) so that
    // we can use the address of loc0.
    let (__fp__, _) = get_fp_and_pc();
    check_solution(
        loc_list=cast(&loc_tuple, Location*),
        tile_list=cast(&tiles, felt*),
        n_steps=4,
    );
    return ();
}