#include <cstdio>
#include <vector>

#include <libff/algebra/curves/mnt753/mnt4753/mnt4753_pp.hpp>
#include <libff/algebra/curves/mnt753/mnt6753/mnt6753_pp.hpp>

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

// The actual code for doing the group operations lives in
// libff/algebra/curves/mnt753/mnt4753/mnt4753_g1.tcc
// libff/algebra/curves/mnt753/mnt4753/mnt4753_g2.tcc
// libff/algebra/curves/mnt753/mnt6753/mnt6753_g1.tcc
// libff/algebra/curves/mnt753/mnt6753/mnt6753_g2.tcc
int main(int argc, char *argv[])
{
    // argv should be
    // { "main", "compute", inputs, outputs }

    mnt4753_pp::init_public_params();
    mnt6753_pp::init_public_params();

    size_t n;

    auto inputs = fopen(argv[2], "r");
    auto outputs = fopen(argv[3], "w");

    while (true) {
      size_t elts_read = fread((void *) &n, sizeof(size_t), 1, inputs);
      if (elts_read == 0) { break; }

      // Read input
      std::vector<G1<mnt4753_pp>> g4_1;
      for (size_t i = 0; i < n; ++i) { g4_1.emplace_back(read_mnt4_g1(inputs)); }

      std::vector<G2<mnt4753_pp>> g4_2;
      for (size_t i = 0; i < n; ++i) { g4_2.emplace_back(read_mnt4_g2(inputs)); }

      std::vector<G1<mnt6753_pp>> g6_1;
      for (size_t i = 0; i < n; ++i) { g6_1.emplace_back(read_mnt6_g1(inputs)); }

      std::vector<G2<mnt6753_pp>> g6_2;
      for (size_t i = 0; i < n; ++i) { g6_2.emplace_back(read_mnt6_g2(inputs)); }

      // Perform the computation
      G1<mnt4753_pp> h4_1 = G1<mnt4753_pp>::zero();
      for (size_t i = 0; i < n; ++i) { h4_1 = h4_1 + g4_1[i]; }

      G2<mnt4753_pp> h4_2 = G2<mnt4753_pp>::zero();
      for (size_t i = 0; i < n; ++i) { h4_2 = h4_2 + g4_2[i]; }

      G1<mnt6753_pp> h6_1 = G1<mnt6753_pp>::zero();
      for (size_t i = 0; i < n; ++i) { h6_1 = h6_1 + g6_1[i]; }

      G2<mnt6753_pp> h6_2 = G2<mnt6753_pp>::zero();
      for (size_t i = 0; i < n; ++i) { h6_2 = h6_2 + g6_2[i]; }

      // Write output
      write_mnt4_g1(outputs, h4_1);
      write_mnt4_g2(outputs, h4_2);
      write_mnt6_g1(outputs, h6_1);
      write_mnt6_g2(outputs, h6_2);
    }
    fclose(outputs);

    return 0;
}
