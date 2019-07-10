#!/usr/bin/env python3


import sys
import time


with open(sys.argv[1]) as fp:
    program = fp.read()

tape = [0] * 2000
tc = 0
pc = 0
while pc < len(program):
    c = program[pc]
    if c == '+':
        tape[tc] += 1
    elif c == '-':
        tape[tc] -= 1
    elif c == '<':
        # assert tc > 0, tc
        tc -= 1
    elif c == '>':
        tc += 1
    elif c == '[' and tape[tc] == 0:
        depth = 1
        while depth:
            pc += 1
            if program[pc] == ']':
                depth -= 1
            elif program[pc] == '[':
                depth += 1
    elif c == ']' and tape[tc] != 0:
        depth = 1
        while depth:
            pc -= 1
            if program[pc] == '[':
                depth -= 1
            elif program[pc] == ']':
                depth += 1
    elif c == '.':
        sys.stdout.write(chr(tape[tc]))
        sys.stdout.flush()
    elif c == ',':
        tape[tc] = ord(sys.stdin.read(1) or '\0')

    # Try to emulate how slow the make version can be...
    # time.sleep(0.001)
    pc += 1
