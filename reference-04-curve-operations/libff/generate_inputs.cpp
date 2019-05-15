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

int main(void)
{
    mnt4753_pp::init_public_params();
    mnt6753_pp::init_public_params();

    setbuf(stdout, NULL);

    size_t n;

    auto output = fopen("inputs", "w");

    size_t num_instances = 1;

    srand(time(NULL));
    for (size_t j = 0; j < num_instances; ++j) {
      size_t n = 1 << (16 + j);

      fwrite((void *) &n, sizeof(size_t), 1, output);

      uint64_t offset = rand();
      for (size_t i = 0; i < n; ++i) {
        Fq<mnt4753_pp> x = SHA512_rng<Fq<mnt4753_pp>>(offset + i);
        Fq<mnt4753_pp> y; 

        while (true) {
          Fq<mnt4753_pp> y2 = x * x.squared() + G1<mnt4753_pp>::coeff_a * x + G1<mnt4753_pp>::coeff_b ;
          Fq<mnt4753_pp> y2e = y2 ^ Fq<mnt4753_pp>::euler;
          bool y2_is_square = y2e == Fq<mnt4753_pp>::one();

          if (y2_is_square) {
            y = y2.sqrt();
            break;
          } else {
            x += 1;
          }
        }

        write_mnt4_g1(output, G1<mnt4753_pp>(x, y, Fq<mnt4753_pp>::one()));
      }
      printf("Done G1");

      offset = rand();

      std::vector<G2<mnt4753_pp>> g4_2(n, G2<mnt4753_pp>::one());
#ifdef MULTICORE
#pragma omp parallel for
#endif
      for (size_t i = 0; i < n; ++i) {
        Fqe<mnt4753_pp> x;
        Fqe<mnt4753_pp> y;

        while (true) {
          Fq<mnt4753_pp> x0 = SHA512_rng<Fq<mnt4753_pp>>(offset);
          Fq<mnt4753_pp> x1 = SHA512_rng<Fq<mnt4753_pp>>(offset + 1);
          offset += 2;

          x = Fqe<mnt4753_pp>(x0, x1);

          Fqe<mnt4753_pp> y2 = x * x.squared() + G2<mnt4753_pp>::coeff_a * x + G2<mnt4753_pp>::coeff_b ;
          Fqe<mnt4753_pp> y2e = y2 ^ Fqe<mnt4753_pp>::euler;
          bool y2_is_square = y2e == Fqe<mnt4753_pp>::one();

          if (y2_is_square) {
            y = y2.sqrt();
            break;
          }
        }

        g4_2[i] = G2<mnt4753_pp>(x, y, Fqe<mnt4753_pp>::one());
      }

      for (size_t i = 0; i < n; ++i) {
        write_mnt4_g2(output, g4_2[i]);
      }

      offset = rand();
      for (size_t i = 0; i < n; ++i) {
        Fq<mnt6753_pp> x = SHA512_rng<Fq<mnt6753_pp>>(offset + i);
        Fq<mnt6753_pp> y; 

        while (true) {
          Fq<mnt6753_pp> y2 = x * x.squared() + G1<mnt6753_pp>::coeff_a * x + G1<mnt6753_pp>::coeff_b ;
          Fq<mnt6753_pp> y2e = y2 ^ Fq<mnt6753_pp>::euler;
          bool y2_is_square = y2e == Fq<mnt6753_pp>::one();

          if (y2_is_square) {
            y = y2.sqrt();
            break;
          } else {
            x += 1;
          }
        }

        write_mnt6_g1(output, G1<mnt6753_pp>(x, y, Fq<mnt6753_pp>::one()));
      }
      printf("Done mnt6 G1");

      offset = rand();

      std::vector<G2<mnt6753_pp>> g6_2(n, G2<mnt6753_pp>::one());
#ifdef MULTICORE
#pragma omp parallel for
#endif
      for (size_t i = 0; i < n; ++i) {
        Fqe<mnt6753_pp> x;
        Fqe<mnt6753_pp> y;

        while (true) {
          Fq<mnt6753_pp> x0 = SHA512_rng<Fq<mnt6753_pp>>(offset);
          Fq<mnt6753_pp> x1 = SHA512_rng<Fq<mnt6753_pp>>(offset + 1);
          Fq<mnt6753_pp> x2 = SHA512_rng<Fq<mnt6753_pp>>(offset + 2);
          offset += 3;

          x = Fqe<mnt6753_pp>(x0, x1, x2);

          Fqe<mnt6753_pp> y2 = x * x.squared() + G2<mnt6753_pp>::coeff_a * x + G2<mnt6753_pp>::coeff_b ;
          Fqe<mnt6753_pp> y2e = y2 ^ Fqe<mnt6753_pp>::euler;
          bool y2_is_square = y2e == Fqe<mnt6753_pp>::one();

          if (y2_is_square) {
            y = y2.sqrt();
            break;
          }
        }

        g6_2[i] = G2<mnt6753_pp>(x, y, Fqe<mnt6753_pp>::one());
      }

      for (size_t i = 0; i < n; ++i) {
        write_mnt6_g2(output, g6_2[i]);
      }
    }
}
