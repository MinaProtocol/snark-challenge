#include <cstdio>
#include <cstdlib>
#include <vector>

#include <libff/algebra/curves/mnt753/mnt4753/mnt4753_pp.hpp>
#include <libff/common/rng.hpp>

using namespace libff;

void write_mnt4_fq(FILE* output, Fq<mnt4753_pp> x) {
  fwrite((void *) x.mont_repr.data, libff::mnt4753_q_limbs * sizeof(mp_size_t), 1, output);
}

void write_mnt4_fq2(FILE* output, Fqe<mnt4753_pp> x) {
  write_mnt4_fq(output, x.c0);
  write_mnt4_fq(output, x.c1);
}

int main(void)
{
    mnt4753_pp::init_public_params();

    auto output = fopen("inputs", "w");

    size_t num_instances = 10;

    srand(time(NULL));
    for (size_t j = 0; j < num_instances; ++j) {
      size_t n = 1 << (10 + j);

      fwrite((void *) &n, sizeof(size_t), 1, output);

      uint64_t offset = rand();
      for (size_t i = 0; i < n; ++i) {
        Fq<mnt4753_pp> c0 = SHA512_rng<Fq<mnt4753_pp>>(offset + 2 * i);
        Fq<mnt4753_pp> c1 = SHA512_rng<Fq<mnt4753_pp>>(offset + 2 * i + 1);
        write_mnt4_fq2(output, Fqe<mnt4753_pp>(c0, c1));
      }

      offset = rand();
      for (size_t i = 0; i < n; ++i) {
        Fq<mnt4753_pp> c0 = SHA512_rng<Fq<mnt4753_pp>>(offset + 2 * i);
        Fq<mnt4753_pp> c1 = SHA512_rng<Fq<mnt4753_pp>>(offset + 2 * i + 1);
        write_mnt4_fq2(output, Fqe<mnt4753_pp>(c0, c1));
      }
    }
}

