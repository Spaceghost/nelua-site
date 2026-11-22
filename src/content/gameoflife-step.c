void gameoflife_GameState_step(gameoflife_GameState_ptr self) {
  for(int64_t y = 0; y <= 14; y += 1) {
    for(int64_t x = 0; x <= 39; x += 1) {
      gameoflife_CellField_set_alive(self->b, x, y, gameoflife_CellField_next(self->a, x, y));
    }
  }
  gameoflife_CellField_ptr _asgntmp_1 = self->a;
  self->a = self->b;
  self->b = _asgntmp_1;
}
