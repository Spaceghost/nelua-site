import Base

def nelua_lower_function1(+nelua_lower_value2: U32, +nelua_lower_value3: U32, +nelua_lower_value4: U32, +nelua_lower_value5: U32) -> U32:
  U32.add(nelua_lower_value2, U32.mul(U32.add(0, 256), U32.add(nelua_lower_value3, U32.mul(U32.add(0, 256), U32.add(nelua_lower_value4, U32.mul(U32.add(0, 256), nelua_lower_value5))))))

def pack_word(x1: U32, x2: U32, x3: U32, x4: U32) -> U32:
  nelua_lower_function1(x1, x2, x3, x4)
