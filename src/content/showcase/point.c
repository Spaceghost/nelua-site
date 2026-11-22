int nelua_main(int argc, char** argv) {
  point_finish = (point_Point){.x = (point_start.x + 5), .y = point_start.y};
  nelua_print_1(point_finish.x, point_finish.y);
  return 0;
}
