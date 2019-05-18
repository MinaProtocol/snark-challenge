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
#include <libsnark/knowledge_commitment/knowledge_commitment.hpp>
#include <libsnark/reductions/r1cs_to_qap/r1cs_to_qap.hpp>

#include <libsnark/zk_proof_systems/ppzksnark/r1cs_gg_ppzksnark/r1cs_gg_ppzksnark.hpp>

#include <libfqfft/evaluation_domain/domains/basic_radix2_domain.hpp>

using namespace libff;
using namespace libsnark;

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

Fq<mnt4753_pp> read_mnt4_fq(FILE* input) {
  Fq<mnt4753_pp> x;
  fread((void *) x.mont_repr.data, libff::mnt4753_q_limbs * sizeof(mp_size_t), 1, input);
  return x;
}

Fq<mnt6753_pp> read_mnt6_fq(FILE* input) {
  Fq<mnt6753_pp> x;
  fread((void *) x.mont_repr.data, libff::mnt6753_q_limbs * sizeof(mp_size_t), 1, input);
  return x;
}

Fqe<mnt4753_pp> read_mnt4_fq2(FILE* input) {
  Fq<mnt4753_pp> c0 = read_mnt4_fq(input);
  Fq<mnt4753_pp> c1 = read_mnt4_fq(input);
  return Fqe<mnt4753_pp>(c0, c1);
}

void write_mnt6_fq3(FILE* output, Fqe<mnt6753_pp> x) {
  write_mnt6_fq(output, x.c0);
  write_mnt6_fq(output, x.c1);
  write_mnt6_fq(output, x.c2);
}

Fqe<mnt6753_pp> read_mnt6_fq3(FILE* input) {
  Fq<mnt6753_pp> c0 = read_mnt6_fq(input);
  Fq<mnt6753_pp> c1 = read_mnt6_fq(input);
  Fq<mnt6753_pp> c2 = read_mnt6_fq(input);
  return Fqe<mnt6753_pp>(c0, c1, c2);
}

G1<mnt4753_pp> read_mnt4_g1(FILE* input) {
  Fq<mnt4753_pp> x = read_mnt4_fq(input);
  Fq<mnt4753_pp> y = read_mnt4_fq(input);
  return G1<mnt4753_pp>(x, y, Fq<mnt4753_pp>::one());
}

G1<mnt6753_pp> read_mnt6_g1(FILE* input) {
  Fq<mnt6753_pp> x = read_mnt6_fq(input);
  Fq<mnt6753_pp> y = read_mnt6_fq(input);
  return G1<mnt6753_pp>(x, y, Fq<mnt6753_pp>::one());
}

G2<mnt4753_pp> read_mnt4_g2(FILE* input) {
  Fqe<mnt4753_pp> x = read_mnt4_fq2(input);
  Fqe<mnt4753_pp> y = read_mnt4_fq2(input);
  return G2<mnt4753_pp>(x, y, Fqe<mnt4753_pp>::one());
}

G2<mnt6753_pp> read_mnt6_g2(FILE* input) {
  Fqe<mnt6753_pp> x = read_mnt6_fq3(input);
  Fqe<mnt6753_pp> y = read_mnt6_fq3(input);
  return G2<mnt6753_pp>(x, y, Fqe<mnt6753_pp>::one());
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

typedef mnt4753_pp ppT;
typedef Fr<ppT> F;

int main(int argc, const char * argv[])
{
    srand(time(NULL));
    setbuf(stdout, NULL);

    ppT::init_public_params();

    auto parameters = fopen(argv[2], "r");
    printf("par: %s\n", argv[2]);

    size_t d = read_size_t(parameters);
    size_t m = read_size_t(parameters);

    std::vector<F> ca(d+1, F::zero());
    for (size_t i = 0; i < d+1; ++i) {
      ca[i] = read_mnt4_fr(parameters); 
    }

    std::vector<F> cb(d+1, F::zero());
    for (size_t i = 0; i < d+1; ++i) {
      cb[i] = read_mnt4_fr(parameters); 
    }

    std::vector<F> cc(d+1, F::zero());
    for (size_t i = 0; i < d+1; ++i) {
      cc[i] = read_mnt4_fr(parameters); 
    }

    std::vector<G1<ppT>> A(m + 1, G1<ppT>::zero());
    for (size_t i = 0; i < m+1; ++i) {
      A[i] = read_mnt4_g1(parameters); 
    }

    std::vector<G1<ppT>> B1(m + 1, G1<ppT>::zero());
    for (size_t i = 0; i < m+1; ++i) {
      B1[i] = read_mnt4_g1(parameters); 
    }

    std::vector<G2<ppT>> B2(m + 1, G2<ppT>::zero());
    for (size_t i = 0; i < m+1; ++i) {
      B2[i] = read_mnt4_g2(parameters); 
    }

    std::vector<G1<ppT>> L(m - 1, G1<ppT>::zero());
    for (size_t i = 0; i < m-1; ++i) {
      L[i] = read_mnt4_g1(parameters); 
    }

    std::vector<G1<ppT>> T(d, G1<ppT>::zero());
    for (size_t i = 0; i < d; ++i) {
      T[i] = read_mnt4_g1(parameters); 
    }

    fclose(parameters);

    printf("0\n");

    auto inputs = fopen(argv[3], "r");
    std::vector<F> w(m+1);
    for (size_t i = 0; i < m+1; ++i) {
      w[i] = read_mnt4_fr(inputs);
    }
    F r = read_mnt4_fr(inputs);
    fclose(inputs);

    printf("1\n");

    const size_t chunks = omp_get_max_threads();

    libff::G1<ppT> proof_A = multi_exp_with_mixed_addition<G1<ppT>,
                                                           Fr<ppT>,
                                                           multi_exp_method_BDLO12>(
        A.begin(),
        A.begin() + m + 1,
        w.begin(),
        w.begin() + m + 1,
        chunks);

    libff::G1<ppT> proof_L = multi_exp_with_mixed_addition<G1<ppT>,
                                                           Fr<ppT>,
                                                           multi_exp_method_BDLO12>(
        L.begin(),
        L.end(),
        w.begin() + 2,
        w.begin() + m + 1,
        chunks);

    /*
    libff::G1<ppT> proof_B1 = multi_exp_with_mixed_addition<G1<ppT>,
                                                           Fr<ppT>,
                                                           multi_exp_method_BDLO12>(
        B1.begin(),
        B1.begin() + m + 1,
        w.begin(),
        w.begin() + m + 1,
        chunks);

    libff::G2<ppT> proof_B2 = multi_exp_with_mixed_addition<G2<ppT>,
                                                           Fr<ppT>,
                                                           multi_exp_method_BDLO12>(
        B2.begin(),
        B2.begin() + m + 1,
        w.begin(),
        w.begin() + m + 1,
        chunks); */

    std::vector<knowledge_commitment<libff::G2<ppT>, libff::G1<ppT> >> B_query0;
    for (size_t i = 0; i < B1.size(); ++i) {
      B_query0.emplace_back(knowledge_commitment<libff::G2<ppT>, libff::G1<ppT> >(B2[i], B1[i]));
    }

    knowledge_commitment_vector<libff::G2<ppT>, libff::G1<ppT> > B_query(std::move(B_query0));

    knowledge_commitment<G2<ppT>, G1<ppT> > BB = kc_multi_exp_with_mixed_addition<G2<ppT>,
                                                                                             G1<ppT>,
                                                                                             Fr<ppT>,
                                                                                             multi_exp_method_BDLO12>(
        B_query,
        0,
        m + 1,
        w.begin(),
        w.begin() + m + 1,
        chunks);

    libff::G1<ppT> proof_B1 = BB.h;
    libff::G2<ppT> proof_B2 = BB.g;

    F d1 = F::random_element();
    F d2 = d1;
    F d3 = d1;

    // Now to compute the array H

    std::vector<F> H;
    bool err;
    libfqfft::basic_radix2_domain<F> domain(d+1, err);
    assert (!err);
    domain.iFFT(ca);
    domain.iFFT(cb);

    // ZK patch
    std::vector<F> coefficients_for_H(domain.m+1, F::zero());
#ifdef MULTICORE
#pragma omp parallel for
#endif
    /* add coefficients of the polynomial (d2*A + d1*B - d3) + d1*d2*Z */
    for (size_t i = 0; i < domain.m; ++i)
    {
        coefficients_for_H[i] = d2*ca[i] + d1*cb[i];
    }
    coefficients_for_H[0] -= d3;
    domain.add_poly_Z(d1*d2, coefficients_for_H);

    domain.cosetFFT(ca, F::multiplicative_generator);
    domain.cosetFFT(cb, F::multiplicative_generator);

    std::vector<F> &H_tmp = ca; // can overwrite ca because it is not used later
#ifdef MULTICORE
#pragma omp parallel for
#endif
    for (size_t i = 0; i < domain.m; ++i)
    {
        H_tmp[i] = ca[i]*cb[i];
    }
    std::vector<F>().swap(cb); // destroy aB
    domain.iFFT(cc);
    domain.cosetFFT(cc, F::multiplicative_generator);

#ifdef MULTICORE
#pragma omp parallel for
#endif
    for (size_t i = 0; i < domain.m; ++i)
    {
        H_tmp[i] = (H_tmp[i]-cc[i]);
    }

    domain.divide_by_Z_on_coset(H_tmp);
    domain.icosetFFT(H_tmp, F::multiplicative_generator);

#ifdef MULTICORE
#pragma omp parallel for
#endif
    for (size_t i = 0; i < domain.m; ++i)
    {
        coefficients_for_H[i] += H_tmp[i];
    }

    libff::G1<ppT> proof_H = multi_exp_with_mixed_addition<G1<ppT>,
                                                           Fr<ppT>,
                                                           multi_exp_method_BDLO12>(
        T.begin(),
        T.begin() + (d - 1),
        coefficients_for_H.begin(),
        coefficients_for_H.begin() + (d - 1),
        chunks);


    proof_A.print();
    proof_B1.print();
    proof_B2.print();
    proof_L.print();
    proof_H.print();
}
