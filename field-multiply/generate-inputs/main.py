#!/usr/bin/env python3

""" Generate pairs of random large integers """

import random
import sys
import json

# large prime int
field_order = int("""
4189849096791895340234421479124063712817070991995394907178350
2921025352812571106773058893763790338921418070971888253786114
3537265295843852015916057220131264689314043479498405430079863
27743462853720628051692141265303114721689601""".replace("\n", ""))

COUNT = 10_000


def random_field_elt():
    # uses string representation for json conversion
    return str(random.randint(0, field_order))


def generate_input():
    return [[random_field_elt(), random_field_elt()] for _ in range(COUNT)]


if __name__ == '__main__':
    print('Generating %s random input pairs in json format' % (COUNT),
          file=sys.stderr)
    print(json.dumps(generate_input(), indent=2))
    print('')
