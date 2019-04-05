import random
import sys
import json

field_order = 41898490967918953402344214791240637128170709919953949071783502921025352812571106773058893763790338921418070971888253786114353726529584385201591605722013126468931404347949840543007986327743462853720628051692141265303114721689601

N = 1000

def random_field_elt():
    return str(random.randint(0, field_order))

def generate_input():
    return [ [ random_field_elt(), random_field_elt()] for _ in range(N) ]

if __name__ == '__main__':
    json.dump(generate_input(), sys.stdout)
