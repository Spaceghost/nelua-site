import Base

def nelua_lower_branch5(test: Bool, +nelua_lower_value2: U32, +nelua_lower_value3: U32) -> U32:
  match test:
    case True{}:
      nelua_lower_value2
    case False{}:
      U32.add(0, 0)

def nelua_lower_branch4(test: Bool, +nelua_lower_value2: U32, +nelua_lower_value3: U32) -> U32:
  match test:
    case True{}:
      U32.add(0, 1)
    case False{}:
      nelua_lower_branch5(U32.is_eq(nelua_lower_value3, U32.add(0, 2)), nelua_lower_value2, nelua_lower_value3)

def nelua_lower_function1(+nelua_lower_value2: U32, +nelua_lower_value3: U32) -> U32:
  nelua_lower_branch4(U32.is_eq(nelua_lower_value3, U32.add(0, 3)), nelua_lower_value2, nelua_lower_value3)

def survives(x1: U32, x2: U32) -> U32:
  nelua_lower_function1(x1, x2)
