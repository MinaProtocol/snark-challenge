/**
 *****************************************************************************
 * @author     This file is part of libfqfft, developed by SCIPR Lab
 *             and contributors (see AUTHORS).
 * @copyright  MIT license (see LICENSE file)
 *****************************************************************************/

#include <memory>
#include <vector>

#include <libff/algebra/curves/mnt753/mnt4753/mnt4753_pp.hpp>
#include <stdint.h>

#include <libfqfft/evaluation_domain/domains/arithmetic_sequence_domain.hpp>
#include <libfqfft/evaluation_domain/get_evaluation_domain.hpp>
#include <libfqfft/evaluation_domain/domains/basic_radix2_domain.hpp>
#include <libfqfft/evaluation_domain/domains/extended_radix2_domain.hpp>
#include <libfqfft/evaluation_domain/domains/geometric_sequence_domain.hpp>
#include <libfqfft/evaluation_domain/domains/step_radix2_domain.hpp>
#include <libfqfft/polynomial_arithmetic/naive_evaluate.hpp>
#include <libfqfft/tools/exceptions.hpp>

using namespace libfqfft;

  int main() {
  typedef libff::mnt4753_pp pp;
  typedef libff::Fr<pp> FieldT;

  const mp_size_t r_limbs = libff::mnt4753_r_limbs;

  size_t m;

  std::vector<FieldT> elements;

  pp::init_public_params();

  m = 1 << 20;
  auto output = fopen("input", "w");
  fwrite((void *) &m, sizeof(size_t), 1, output);
  for (int i = 0; i < m; ++i) {
    libff::bigint<r_limbs> x = FieldT::random_element().as_bigint();
    fwrite((void*) x.data, r_limbs * sizeof(mp_size_t), 1, output);
  }
  fclose(output);
  printf("done\n");
}

 // libfqfft
