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

  auto input = fopen("input", "r");
  size_t elts_read = 0;

  printf("Begin reading input\n");
  fread((void*) &m, sizeof(size_t), 1, input);
  libff::bigint<r_limbs> tmp;
  while (elts_read < m) {
    fread((void*) tmp.data, r_limbs * sizeof(mp_size_t), 1, input);
    elements.emplace_back(FieldT(tmp));
    ++elts_read;
  }
  fclose(input);
  printf("End reading input\n");

  printf("Begin FFT\n");
  const std::shared_ptr<evaluation_domain<FieldT> > domain =
    get_evaluation_domain<FieldT>(m);

  domain->FFT(elements);
  printf("End FFT\n");

  printf("Begin writing output\n");
  auto output = fopen("output", "w");
  fwrite((void *) &m, sizeof(size_t), 1, output);
  for (int i = 0; i < m; ++i) {
    libff::bigint<r_limbs> x = elements[i].as_bigint();
    fwrite((void*) x.data, r_limbs * sizeof(mp_size_t), 1, output);
  }
  fclose(output);
  printf("End writing output\n");
}

 // libfqfft
