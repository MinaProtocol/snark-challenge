#include <cassert>
#include <cstdio>

#include <libff/common/rng.hpp>
#include <libff/common/profiling.hpp>
#include <libff/common/utils.hpp>

#include <libff/algebra/curves/mnt753/mnt4753/mnt4753_pp.hpp>
#include <libff/algebra/curves/mnt753/mnt6753/mnt6753_pp.hpp>
#include <omp.h>
#include <libff/algebra/scalar_multiplication/multiexp.hpp>
#include <libsnark/knowledge_commitment/kc_multiexp.hpp>
#include <libsnark/reductions/r1cs_to_qap/r1cs_to_qap.hpp>

#include <libsnark/zk_proof_systems/ppzksnark/r1cs_gg_ppzksnark/r1cs_gg_ppzksnark.hpp>

using namespace libsnark;
using namespace libff;

void write_size_t(FILE* output, size_t n) {
  fwrite((void *) &n, sizeof(size_t), 1, output);
}

void write_mnt4_fr(FILE* output, Fr<mnt4753_pp> x) {
  fwrite((void *) x.mont_repr.data, libff::mnt4753_r_limbs * sizeof(mp_size_t), 1, output);
}

void write_mnt4_fq(FILE* output, Fq<mnt4753_pp> x) {
  fwrite((void *) x.mont_repr.data, libff::mnt4753_q_limbs * sizeof(mp_size_t), 1, output);
}

void write_mnt6_fq(FILE* output, Fq<mnt6753_pp> x) {
  fwrite((void *) x.mont_repr.data, libff::mnt6753_q_limbs * sizeof(mp_size_t), 1, output);
}

Fr<mnt4753_pp> read_mnt4_fr(FILE* input) {
  Fr<mnt4753_pp> x;
  fread((void *) x.mont_repr.data, libff::mnt4753_r_limbs * sizeof(mp_size_t), 1, input);
  return x;
}

size_t read_size_t(FILE* input) {
  size_t n;
  fread((void *) &n, sizeof(size_t), 1, input);
  return n;
}

typedef mnt4753_pp pp;
typedef Fr<pp> F;

int main(int argc, const char * argv[])
{
    srand(time(NULL));
    setbuf(stdout, NULL);

    mnt4753_pp::init_public_params();

    auto parameters = fopen("parameters", "r");

    size_t d = read_size_t(parameters);
    size_t m = read_size_t(parameters);

    uint64_t offset = rand();

    std::vector<F> w(m+1, F::zero());
    for (size_t i = 0; i < m+1; ++i) {
      w[i] = SHA512_rng<F>(offset);
    }
    offset += m+1;

    F r = SHA512_rng<F>(offset);

    auto output = fopen("inputs", "w");
    for (size_t i = 0; i < m+1; ++i) {
      write_mnt4_fr(output, w[i]);
    }
    write_mnt4_fr(output, r);
}
