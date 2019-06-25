#include <cstdio>
#include <vector>

#include <libff/algebra/curves/mnt753/mnt6753/mnt6753_pp.hpp>
#include <libff/algebra/curves/mnt753/mnt6753/mnt6753_init.hpp>

using namespace libff;

void write_mnt6_fq(FILE* output, Fq<mnt6753_pp> x) {
  fwrite((void *) x.mont_repr.data, libff::mnt6753_q_limbs * sizeof(mp_size_t), 1, output);
}

Fq<mnt6753_pp> read_mnt6_fq(FILE* input) {
  // bigint<mnt6753_q_limbs> n;
  Fq<mnt6753_pp> x;
  fread((void *) x.mont_repr.data, libff::mnt6753_q_limbs * sizeof(mp_size_t), 1, input);
  return x;
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

void write_mnt6_fq_numeral(FILE* output, Fq<mnt6753_pp> x) {
  auto out_numeral = x.as_bigint();
  fwrite((void *) out_numeral.data, libff::mnt6753_q_limbs * sizeof(mp_size_t), 1, output);
}

Fq<mnt6753_pp> read_mnt6_fq_numeral(FILE* input) {
  // bigint<mnt4753_q_limbs> n;
  Fq<mnt6753_pp> x;
  fread((void *) x.mont_repr.data, libff::mnt6753_q_limbs * sizeof(mp_size_t), 1, input);
  auto b = Fq<mnt6753_pp>(x.mont_repr);
  return b;
}

void write_mnt6_fq3_numeral(FILE* output, Fqe<mnt6753_pp> x) {
  write_mnt6_fq_numeral(output, x.c0);
  write_mnt6_fq_numeral(output, x.c1);
  write_mnt6_fq_numeral(output, x.c2);
}

Fqe<mnt6753_pp> read_mnt6_fq3_numeral(FILE* input) {
  Fq<mnt6753_pp> c0 = read_mnt6_fq_numeral(input);
  Fq<mnt6753_pp> c1 = read_mnt6_fq_numeral(input);
  Fq<mnt6753_pp> c2 = read_mnt6_fq_numeral(input);
  return Fqe<mnt6753_pp>(c0, c1, c2);
}

// The actual code for doing Fq3 multiplication lives in libff/algebra/fields/fp3.tcc
int main(int argc, char *argv[])
{
    // argv should be
    // { "main", "compute", inputs, outputs }

    mnt6753_pp::init_public_params();
    auto is_numeral = strcmp(argv[1], "compute-numeral") == 0;
    auto inputs = fopen(argv[2], "r");
    auto outputs = fopen(argv[3], "w");

    auto read_mnt6 = read_mnt6_fq;
    auto write_mnt6 = write_mnt6_fq;
    auto read_mnt6_q3 = read_mnt6_fq3;
    auto write_mnt6_q3 = write_mnt6_fq3;
    if (is_numeral) {
      read_mnt6 = read_mnt6_fq_numeral;
      write_mnt6 = write_mnt6_fq_numeral;
      read_mnt6_q3 = read_mnt6_fq3_numeral;
      write_mnt6_q3 = write_mnt6_fq3_numeral;
    }

    while (true) {
      size_t n;
      size_t elts_read = fread((void *) &n, sizeof(size_t), 1, inputs);

      if (elts_read == 0) { break; }

      std::vector<Fqe<mnt6753_pp>> x;
      for (size_t i = 0; i < n; ++i) {
        x.emplace_back(read_mnt6_q3(inputs));
      }

      std::vector<Fqe<mnt6753_pp>> y;
      for (size_t i = 0; i < n; ++i) {
        y.emplace_back(read_mnt6_q3(inputs));
      }

      for (size_t i = 0; i < n; ++i) {
        write_mnt6_q3(outputs, x[i] * y[i]);
      }
    }
    fclose(outputs);

    return 0;
}
