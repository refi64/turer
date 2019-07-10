#!/usr/bin/env python3

with open('number-values.mk', 'w') as fp:
    print('# Auto-generated by generate-number-values.py.', file=fp)
    for i in range(256):
        print(f'value_{i} := {" ".join("x" * i)}', file=fp)