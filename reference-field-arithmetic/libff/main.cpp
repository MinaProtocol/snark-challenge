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

// The actual code for doing Fq multiplication lives in libff/algebra/fields/fp.tcc
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

      std::vector<Fq<mnt4753_pp>> x;
      for (size_t i = 0; i < n; ++i) {
        x.emplace_back(read_mnt4_fq(inputs));
      }

      std::vector<Fq<mnt6753_pp>> y;
      for (size_t i = 0; i < n; ++i) {
        y.emplace_back(read_mnt6_fq(inputs));
      }

      Fq<mnt4753_pp> out_x = Fq<mnt4753_pp>::one();
      for (size_t i = 0; i < n; ++i) {
        out_x *= x[i];
      }

      Fq<mnt6753_pp> out_y = Fq<mnt6753_pp>::one();
      for (size_t i = 0; i < n; ++i) {
        out_y *= y[i];
      }

      write_mnt4_fq(outputs, out_x);
      write_mnt6_fq(outputs, out_y);
    }
    fclose(outputs);

    return 0;
}
