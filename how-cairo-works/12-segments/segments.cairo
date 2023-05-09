%builtins output

func main(output_ptr: felt*) -> (output_ptr: felt*) {
    [ap] = output_ptr, ap++;
    %{
        # split ap with ':'
        ap_before_relocate = str(ap).split(':')
        print('ap =', ap)
        if ap_before_relocate[0] == "1":
            # magic number 8 should be known beforehand
            print('relocated ap =', 8 + int(ap_before_relocate[1]))
        output_ptr_before_relocate = str(memory[ap - 1]).split(':')
        print('[ap - 1] =', memory[ap - 1])
        if output_ptr_before_relocate[0] == "2":
            # magic number 14 should be known beforehand
            print('relocated [ap - 1] =', 14 + int(output_ptr_before_relocate[1]))
        print()
    %}
    assert [output_ptr] = 12;
    return (output_ptr=output_ptr + 1);
}