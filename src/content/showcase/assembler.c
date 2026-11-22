static nluint8_arr23 opcode_codes = {.v = {0x0U, 1U, 2U, 3U, 4U, 5U, 6U, 7U, 8U, 9U, 10U, 11U, 12U, 13U, 14U, 15U, 16U, 17U, 18U, 19U, 20U, 21U, 22U}};
uint32_t encode(uint32_t index, uint32_t a, uint32_t b, uint32_t c) {
  if(((((index >= 23) || (a > 15)) || (b > 15)) || (c > 15))) {
    return 0xffffffffULL;
  }
  return pack_word((uint32_t)opcode_codes.v[index], a, b, c);
}
