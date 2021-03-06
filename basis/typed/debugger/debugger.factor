! (c)Joe Groff bsd license
USING: typed compiler.cfg.debugger compiler.tree.debugger
tools.disassembler words ;
IN: typed.debugger

: typed-test-mr ( word -- mrs )
    "typed-word" word-prop test-mr ; inline
: typed-test-mr. ( word -- )
    "typed-word" word-prop test-mr mr. ; inline
: typed-optimized. ( word -- )
    "typed-word" word-prop optimized. ; inline

: typed-disassemble ( word -- )
    "typed-word" word-prop disassemble ; inline
