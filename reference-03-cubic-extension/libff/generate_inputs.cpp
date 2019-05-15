#include <cstdio>
#include <cstdlib>
#include <vector>

#include <libff/algebra/curves/mnt753/mnt6753/mnt6753_pp.hpp>
#include <libff/common/rng.hpp>

using namespace libff;

void write_mnt6_fq(FILE* output, Fq<mnt6753_pp> x) {
  fwrite((void *) x.mont_repr.data, libff::mnt6753_q_limbs * sizeof(mp_size_t), 1, output);
}

void write_mnt6_fq3(FILE* output, Fqe<mnt6753_pp> x) {
  write_mnt6_fq(output, x.c0);
  write_mnt6_fq(output, x.c1);
  write_mnt6_fq(output, x.c2);
}

int main(void)
{
    mnt6753_pp::init_public_params();

    auto output = fopen("inputs", "w");

    size_t num_instances = 10;

    srand(time(NULL));
    for (size_t j = 0; j < num_instances; ++j) {
      size_t n = 1 << (10 + j);

      fwrite((void *) &n, sizeof(size_t), 1, output);

      uint64_t offset = rand();
      for (size_t i = 0; i < n; ++i) {
        Fq<mnt6753_pp> c0 = SHA512_rng<Fq<mnt6753_pp>>(offset + 3 * i);
        Fq<mnt6753_pp> c1 = SHA512_rng<Fq<mnt6753_pp>>(offset + 3 * i + 1);
        Fq<mnt6753_pp> c2 = SHA512_rng<Fq<mnt6753_pp>>(offset + 3 * i + 2);
        write_mnt6_fq3(output, Fqe<mnt6753_pp>(c0, c1, c2));
      }
    }
}

