from starkware.cairo.common.registers import get_fp_and_pc
from starkware.cairo.common.dict_access import DictAccess
from starkware.cairo.common.squash_dict import squash_dict

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


func main() {
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

    // Get the value of the frame pointer register (fp) so that
    // we can use the address of loc_tuple.
    let (__fp__, _) = get_fp_and_pc();
    // Since the tuple elements are next to each other, we can
    // use the address of loc_tuple as a pointer to the 5
    // locations.
    verify_location_list(
        loc_list=cast(&loc_tuple, Location*), n_steps=4
    );
    return ();
}
