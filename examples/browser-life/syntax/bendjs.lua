-- Export pure Nelua functions as host imports implemented by a Bend ES module.
local lower = require 'nelua.bend2lower'
local fs = require 'nelua.utils.fs'

return function(syntax)
  syntax.statement("'bendjs' WORDSKIP `(` {| NAME SKIP (`,` NAME SKIP)* |} @`)` @`do` Block @`end`",
    function(names, block)
      local code, functions = lower.translate(block)
      local output = os.getenv('NELUA_BENDJS_SOURCE')
      if not output then syntax.raise('set NELUA_BENDJS_SOURCE to the output .bend file') end
      local declarations, seen = {}, {}
      for _, name in ipairs(names) do
        local fn = functions[name]
        if not fn or seen[name] then syntax.raise('unknown or repeated bendjs export %q', name) end
        seen[name] = true
        local args, bend, nelua = {}, {}, {}
        for i = 1, fn.arity do
          args[i] = 'x' .. i
          bend[i] = args[i] .. ': U32'
          nelua[i] = args[i] .. ': uint32'
        end
        code = code .. ('\n\ndef %s(%s) -> U32:\n  %s(%s)'):format(
          name, table.concat(bend, ', '), fn.name, table.concat(args, ', '))
        declarations[#declarations + 1] = ('local function %s(%s): uint32 <cimport %q> end')
          :format(name, table.concat(nelua, ', '), name)
      end
      local previous = fs.readfile(output) or ''
      -- Each block uses private lowering names. Keep one block per module.
      if previous ~= '' and previous ~= code .. '\n' then
        syntax.raise('use one bendjs block per build and a fresh NELUA_BENDJS_SOURCE path')
      end
      assert(fs.writefile(output, code .. '\n'))
      return syntax.block(table.concat(declarations, '\n'))
    end)
end
