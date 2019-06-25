#include <cstdio>
#include <vector>

#include <libff/algebra/curves/mnt753/mnt4753/mnt4753_pp.hpp>
#include <libff/algebra/curves/mnt753/mnt6753/mnt6753_pp.hpp>
#include <libff/algebra/curves/mnt753/mnt4753/mnt4753_init.hpp>

using namespace libff;

void write_mnt4_fq(FILE* output, Fq<mnt4753_pp> x) {
  fwrite((void *) x.mont_repr.data, libff::mnt4753_q_limbs * sizeof(mp_size_t), 1, output);
}

void write_mnt6_fq(FILE* output, Fq<mnt6753_pp> x) {
  fwrite((void *) x.mont_repr.data, libff::mnt6753_q_limbs * sizeof(mp_size_t), 1, output);
}

Fq<mnt4753_pp> read_mnt4_fq(FILE* input) {
  // bigint<mnt4753_q_limbs> n;
  Fq<mnt4753_pp> x;
  fread((void *) x.mont_repr.data, libff::mnt4753_q_limbs * sizeof(mp_size_t), 1, input);
  return x;
}

Fq<mnt6753_pp> read_mnt6_fq(FILE* input) {
  // bigint<mnt4753_q_limbs> n;
  Fq<mnt6753_pp> x;
  fread((void *) x.mont_repr.data, libff::mnt6753_q_limbs * sizeof(mp_size_t), 1, input);
  return x;
}

void write_mnt4_fq_numeral(FILE* output, Fq<mnt4753_pp> x) {
  auto out_numeral = x.as_bigint();
  fwrite((void *) out_numeral.data, libff::mnt4753_q_limbs * sizeof(mp_size_t), 1, output);
}

void write_mnt6_fq_numeral(FILE* output, Fq<mnt6753_pp> x) {
  auto out_numeral = x.as_bigint();
  fwrite((void *) out_numeral.data, libff::mnt6753_q_limbs * sizeof(mp_size_t), 1, output);
}

Fq<mnt4753_pp> read_mnt4_fq_numeral(FILE* input) {
  // bigint<mnt4753_q_limbs> n;
  Fq<mnt4753_pp> x;
  fread((void *) x.mont_repr.data, libff::mnt4753_q_limbs * sizeof(mp_size_t), 1, input);
  auto b = Fq<mnt4753_pp>(x.mont_repr);
  return b;
}

Fq<mnt6753_pp> read_mnt6_fq_numeral(FILE* input) {
  // bigint<mnt4753_q_limbs> n;
  Fq<mnt6753_pp> x;
  fread((void *) x.mont_repr.data, libff::mnt6753_q_limbs * sizeof(mp_size_t), 1, input);
  auto b = Fq<mnt6753_pp>(x.mont_repr);
  return b;
}

void print_array(uint8_t* a) {
  for (int j = 0; j < 96; j++) {
    printf("%x ", ((uint8_t*)(a))[j]);
  }
  printf("\n");
}

// The actual code for doing Fq multiplication lives in libff/algebra/fields/fp.tcc
int main(int argc, char *argv[])
{
    // argv should be
    // { "main", "compute", inputs, outputs }

    mnt4753_pp::init_public_params();
    mnt6753_pp::init_public_params();

    size_t n;

    auto is_numeral = strcmp(argv[1], "compute-numeral") == 0;
    auto inputs = fopen(argv[2], "r");
    auto outputs = fopen(argv[3], "w");

    auto read_mnt4 = read_mnt4_fq;
    auto read_mnt6 = read_mnt6_fq;
    auto write_mnt4 = write_mnt4_fq;
    auto write_mnt6 = write_mnt6_fq;
    if (is_numeral) {
      read_mnt4 = read_mnt4_fq_numeral;
      read_mnt6 = read_mnt6_fq_numeral;
      write_mnt4 = write_mnt4_fq_numeral;
      write_mnt6 = write_mnt6_fq_numeral;

    }

    while (true) {
      size_t elts_read = fread((void *) &n, sizeof(size_t), 1, inputs);
      if (elts_read == 0) { break; }

      std::vector<Fq<mnt4753_pp>> x0;
      for (size_t i = 0; i < n; ++i) {
        x0.emplace_back(read_mnt4(inputs));
      }

      std::vector<Fq<mnt4753_pp>> x1;
      for (size_t i = 0; i < n; ++i) {
        x1.emplace_back(read_mnt4(inputs));
      }

      std::vector<Fq<mnt6753_pp>> y0;
      for (size_t i = 0; i < n; ++i) {
        y0.emplace_back(read_mnt6(inputs));
      }
      std::vector<Fq<mnt6753_pp>> y1;
      for (size_t i = 0; i < n; ++i) {
        y1.emplace_back(read_mnt6(inputs));
      }

      for (size_t i = 0; i < n; ++i) {
        write_mnt4(outputs, x0[i] * x1[i]);
      }

      for (size_t i = 0; i < n; ++i) {
        write_mnt6(outputs, y0[i] * y1[i]);
      }
    }
    fclose(outputs);

    return 0;
}
