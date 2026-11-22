export const files = [
  {
    "key": "boot",
    "file": "earlyboot.nelua",
    "project": "Theseus Init",
    "title": "Start the console",
    "note": "Linux gives PID 1 the job of bringing up userspace. Theseus mounts the process and device filesystems before it opens the Nebox shell.",
    "source": "https://github.com/Spaceghost/theseus-init/blob/72095fd70e77da93fada45686459985cee5429d3/src/theseus/earlyboot.nelua#L81-L85",
    "code": "local flags = MS_NODEV | MS_NOEXEC | MS_NOSUID\nmount_one('proc', '/proc', 'proc', flags)\nmount_one('sysfs', '/sys', 'sysfs', flags)\nsetenv('PATH', '/bin:/sbin', 1)\nreport('theseus: starting console shell')"
  },
  {
    "key": "assembler",
    "file": "asm.nelua",
    "project": "Drift",
    "title": "Build an instruction set at compile time",
    "note": "The lines marked ## run Lua inside the compiler. Each pass splices a name into a Nelua declaration, giving the driver assembler a typed constant for every opcode.",
    "source": "https://github.com/Spaceghost/drift/blob/c97083292cdd831a80cb51c3f76f0879088969bd/lib/drift/asm.nelua#L8-L13",
    "code": "## local names = {'HALT','LIT','MOV','ADD','SUB','MUL','DIV','AND','OR',\n##                'XOR','SHL','SHR','LD8','ST8','LD32','ST32','JMP',\n##                'JEQ','JNE','JLT','IO','EVENT','SLEEP'}\n## for i, name in ipairs(names) do\nlocal asm.#|name|#: uint8 <comptime> = #[i-1]#\n## end"
  },
  {
    "key": "life",
    "file": "gameoflife.nelua",
    "project": "Upstream Nelua",
    "title": "Advance a world by one generation",
    "note": "Each cell reads its neighbors from field a and writes its next state to field b. A multiple assignment swaps the two field pointers when the generation is complete.",
    "source": "https://github.com/edubart/nelua-lang/blob/a58450563e2d2ec49bff499865c8b5cfdf6ff81a/examples/gameoflife.nelua#L67-L74",
    "code": "function GameState:step()\n  for y=0,GRID_HEIGHT-1 do\n    for x=0,GRID_WIDTH-1 do\n      self.b:set_alive(x, y, self.a:next(x, y))\n    end\n  end\n  self.a, self.b = self.b, self.a -- swap fields\nend"
  },
  {
    "key": "arena",
    "file": "melodica_core.nelua",
    "project": "Melodica extension",
    "title": "Give a browser extension its own allocator",
    "note": "Melodica exports this function from its WebAssembly module. It rounds each allocation up to eight bytes and hands the caller a pointer into a fixed arena.",
    "source": "https://github.com/Spaceghost/melodica.h/blob/8b5750bd67d9fcd54d6c33a85686b95bdfa60fbd/apps/melodica-extension/core/melodica_core.nelua#L334-L342",
    "code": "local function mx_alloc(n: usize): *[0]byte <cexport, codename 'mx_alloc'>\n  local size: usize = n\n  if size == 0 then size = 1 end\n  size = (size + 7) & ~7_usize\n  if size > ARENA_SIZE - st.arena_top then return nilptr end\n  local start: usize = st.arena_top\n  st.arena_top = start + size\n  return (@*[0]byte)(&st.arena[start])\nend"
  }
];

// Drift assigns i - 1 while iterating the quoted names in this excerpt.
const assembler = files.find(file => file.key === 'assembler');
export const opcodeNames = Array.from(assembler.code.matchAll(/'([A-Z0-9]+)'/g), match => match[1]);
