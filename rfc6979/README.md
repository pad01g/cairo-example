# memo

`crypto` and `utils` are from zerosync project.

# run

```
name=rfc6979 cairo-compile $name/$name.cairo --output $name.json && cairo-run --program=$name.json --print_output --layout=small --print_memory --print_info --trace_file=$name-trace.bin --memory_file=$name-memory.bin  --debug_error --relocate_prints --cairo_path src
```
