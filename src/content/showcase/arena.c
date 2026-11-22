nluint8_arr0_ptr mx_alloc(uintptr_t n) {
  uintptr_t size = n;
  if((size == 0)) {
    size = 1U;
  }
  size = ((size + 7) & 4294967288ULL);
  if((size > (262144U - melodica_core_st.arena_top))) {
    return ((nluint8_arr0_ptr)NULL);
  }
  uintptr_t start = melodica_core_st.arena_top;
  melodica_core_st.arena_top = (start + size);
  return ((nluint8_arr0_ptr)(&melodica_core_st.arena[start]));
}
