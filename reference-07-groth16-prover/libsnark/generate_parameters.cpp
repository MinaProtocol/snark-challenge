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

void write_mnt4_fq2(FILE* output, Fqe<mnt4753_pp> x) {
  write_mnt4_fq(output, x.c0);
  write_mnt4_fq(output, x.c1);
}

void write_mnt6_fq3(FILE* output, Fqe<mnt6753_pp> x) {
  write_mnt6_fq(output, x.c0);
  write_mnt6_fq(output, x.c1);
  write_mnt6_fq(output, x.c2);
}

void write_mnt4_g1(FILE* output, G1<mnt4753_pp> g) {
  g.to_affine_coordinates();
  write_mnt4_fq(output, g.X());
  write_mnt4_fq(output, g.Y());
}

void write_mnt6_g1(FILE* output, G1<mnt6753_pp> g) {
  g.to_affine_coordinates();
  write_mnt6_fq(output, g.X());
  write_mnt6_fq(output, g.Y());
}

void write_mnt4_g2(FILE* output, G2<mnt4753_pp> g) {
  g.to_affine_coordinates();
  write_mnt4_fq2(output, g.X());
  write_mnt4_fq2(output, g.Y());
}

void write_mnt6_g2(FILE* output, G2<mnt6753_pp> g) {
  g.to_affine_coordinates();
  write_mnt6_fq3(output, g.X());
  write_mnt6_fq3(output, g.Y());
}

template<typename ppT>
std::vector<G1<ppT>> random_g1_vector(size_t n) {
  uint64_t offset = rand();

  std::vector<G1<ppT>> res(n, G1<ppT>::one());

#ifdef MULTICORE
#pragma omp parallel for
#endif
  for (size_t i = 0; i < n; ++i) {
    Fq<ppT> x = SHA512_rng<Fq<ppT>>(offset + i);
    Fq<ppT> y; 

    while (true) {
      Fq<ppT> y2 = x * x.squared() + G1<ppT>::coeff_a * x + G1<ppT>::coeff_b ;
      Fq<ppT> y2e = y2 ^ Fq<ppT>::euler;
      bool y2_is_square = y2e == Fq<ppT>::one();

      if (y2_is_square) {
        y = y2.sqrt();
        break;
      } else {
        x += 1;
      }
    }

    res[i] = G1<ppT>(x, y, Fq<ppT>::one());
  }

  return res;
}

template<typename ppT>
std::vector<G2<ppT>> random_g2_vector(size_t n) {
  std::vector<G2<ppT>> res(n, G2<ppT>::one());

  uint64_t offset0 = rand();

#ifdef MULTICORE
#pragma omp parallel for
#endif
  for (size_t i = 0; i < n; ++i) {
    Fqe<ppT> x;
    Fqe<ppT> y;

    uint64_t offset = offset0 + 128 * i;

    while (true) {
      Fq<ppT> x0 = SHA512_rng<Fq<ppT>>(offset);
      Fq<ppT> x1 = SHA512_rng<Fq<ppT>>(offset + 1);
      offset += 2;

      x = Fqe<ppT>(x0, x1);

      Fqe<ppT> y2 = x * x.squared() + G2<ppT>::coeff_a * x + G2<ppT>::coeff_b ;
      Fqe<ppT> y2e = y2 ^ Fqe<ppT>::euler;
      bool y2_is_square = y2e == Fqe<ppT>::one();

      if (y2_is_square) {
        y = y2.sqrt();
        break;
      }
    }

    res[i] = G2<ppT>(x, y, Fqe<ppT>::one());
  }

  return res;
}

typedef mnt4753_pp pp;
typedef Fr<pp> F;

int main(int argc, const char * argv[])
{
    srand(time(NULL));
    setbuf(stdout, NULL);

    mnt4753_pp::init_public_params();

    auto output = fopen("parameters", "w");

    size_t d_plus_1 = 1 << 15;
    size_t d = d_plus_1 - 1;
    size_t K = d / 3;
    size_t m = d + (rand() % (2 * K)) - K;

    printf("d = %d, m = %d\n", d, m);

    std::vector<F> ca(d+1, F::zero());
    std::vector<F> cb(d+1, F::zero());
    std::vector<F> cc(d+1, F::zero());

    uint64_t offset = rand();
    for (size_t i = 0; i < d+1; ++i) {
      ca[i] = SHA512_rng<F>(offset + 3*i);
      cb[i] = SHA512_rng<F>(offset + 3*i + 1);
      cc[i] = SHA512_rng<F>(offset + 3*i + 2);
    }
    printf("0\n");

    std::vector<G1<pp>> A = random_g1_vector<pp>(m + 1);
    printf("1\n");
    std::vector<G1<pp>> B1 = random_g1_vector<pp>(m + 1);
    printf("2\n");
    std::vector<G2<pp>> B2 = random_g2_vector<pp>(m + 1);
    printf("3\n");
    std::vector<G1<pp>> L = random_g1_vector<pp>(m - 1);
    printf("4\n");
    std::vector<G1<pp>> T = random_g1_vector<pp>(d);
    printf("5\n");

    write_size_t(output, d);
    write_size_t(output, m);

    for (size_t i = 0; i < d+1; ++i) { write_mnt4_fr(output, ca[i]); }
    for (size_t i = 0; i < d+1; ++i) { write_mnt4_fr(output, cb[i]); }
    for (size_t i = 0; i < d+1; ++i) { write_mnt4_fr(output, cc[i]); }

    for (size_t i = 0; i < m+1; ++i) { write_mnt4_g1(output, A[i]); }
    for (size_t i = 0; i < m+1; ++i) { write_mnt4_g1(output, B1[i]); }
    for (size_t i = 0; i < m+1; ++i) { write_mnt4_g2(output, B2[i]); }

    for (size_t i = 0; i < m-1; ++i) { write_mnt4_g1(output, L[i]); }
    for (size_t i = 0; i < d; ++i) { write_mnt4_g1(output, T[i]); }
}
