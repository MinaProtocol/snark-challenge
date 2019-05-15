#include <cstdio>
#include <cstdlib>
#include <vector>

#include <libff/algebra/curves/mnt753/mnt4753/mnt4753_pp.hpp>
#include <libff/algebra/curves/mnt753/mnt6753/mnt6753_pp.hpp>
#include <libff/common/rng.hpp>

using namespace libff;

void write_mnt4_fq(FILE* output, Fq<mnt4753_pp> x) {
  fwrite((void *) x.mont_repr.data, libff::mnt4753_q_limbs * sizeof(mp_size_t), 1, output);
}

void write_mnt6_fq(FILE* output, Fq<mnt6753_pp> x) {
  fwrite((void *) x.mont_repr.data, libff::mnt6753_q_limbs * sizeof(mp_size_t), 1, output);
}

int main(void)
{
    mnt4753_pp::init_public_params();
    mnt6753_pp::init_public_params();

    setbuf(stdout, NULL);

    size_t n;

    auto output = fopen("inputs", "w");

    size_t num_instances = 10;

    srand(time(NULL));
    for (size_t j = 0; j < num_instances; ++j) {
      size_t n = 1 << (10 + j);

      fwrite((void *) &n, sizeof(size_t), 1, output);

      uint64_t offset = rand();
      for (size_t i = 0; i < n; ++i) {
        write_mnt4_fq(output, SHA512_rng<Fq<mnt4753_pp>>(offset + i));
      }

      offset = rand();
      for (size_t i = 0; i < n; ++i) {
        write_mnt6_fq(output, SHA512_rng<Fq<mnt6753_pp>>(offset + i));
      }
    }
}

