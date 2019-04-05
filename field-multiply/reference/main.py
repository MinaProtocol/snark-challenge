#!/usr/bin/env python
import sys
import json

field_order = 41898490967918953402344214791240637128170709919953949071783502921025352812571106773058893763790338921418070971888253786114353726529584385201591605722013126468931404347949840543007986327743462853720628051692141265303114721689601

# Mnt4 Fq
class Field:
    def __init__(self, n):
        self.value = n

    def __add__(self, other):
        return Field((self.value + other.value) % field_order)

    def __mul__(self, other):
        return Field((self.value * other.value) % field_order)

    def __eq__(self, other):
        return self.value == other.value

    def __str__(self):
        return str(self.value)

if __name__ == '__main__':
    ps = json.load(sys.stdin)
    output = [ str(Field(int(x)) * Field(int(y))) for [x, y] in ps ]
    json.dump(output, sys.stdout)
