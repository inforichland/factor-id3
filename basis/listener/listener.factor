! Copyright (C) 2003, 2009 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: arrays hashtables io kernel math math.parser memory
namespaces parser lexer sequences strings io.styles
vectors words generic system combinators continuations debugger
definitions compiler.units accessors colors prettyprint fry
sets vocabs.parser source-files.errors locals vocabs vocabs.loader ;
IN: listener

GENERIC: stream-read-quot ( stream -- quot/f )

: parse-lines-interactive ( lines -- quot/f )
    [ parse-lines ] with-compilation-unit ;

: read-quot-step ( lines -- quot/f )
    [ parse-lines-interactive ] [
        dup error>> unexpected-eof?
        [ 2drop f ] [ rethrow ] if
    ] recover ;

: read-quot-loop ( stream accum -- quot/f )
    over stream-readln dup [
        over push
        dup read-quot-step dup
        [ 2nip ] [ drop read-quot-loop ] if
    ] [
        3drop f
    ] if ;

M: object stream-read-quot
    V{ } clone read-quot-loop ;

: read-quot ( -- quot/f ) input-stream get stream-read-quot ;

SYMBOL: visible-vars

: show-var ( var -- ) visible-vars [ swap suffix ] change ;

: show-vars ( seq -- ) visible-vars [ swap union ] change ;

: hide-var ( var -- ) visible-vars [ remove ] change ;

: hide-vars ( seq -- ) visible-vars [ swap diff ] change ;

: hide-all-vars ( -- ) visible-vars off ;

SYMBOL: error-hook

: call-error-hook ( error -- )
    error-continuation get error-hook get
    call( error continuation -- ) ;

[ drop print-error-and-restarts ] error-hook set-global

SYMBOL: display-stacks?

t display-stacks? set-global

SYMBOL: max-stack-items

10 max-stack-items set-global

SYMBOL: error-summary?

t error-summary? set-global

<PRIVATE

: title. ( string -- )
    H{ { foreground T{ rgba f 0.3 0.3 0.3 1 } } } format nl ;

: visible-vars. ( -- )
    visible-vars get [
        nl "--- Watched variables:" title.
        standard-table-style [
            [
                [
                    [ [ short. ] with-cell ]
                    [ [ get short. ] with-cell ]
                    bi
                ] with-row
            ] each
        ] tabular-output nl
    ] unless-empty ;
    
: trimmed-stack. ( seq -- )
    dup length max-stack-items get > [
        max-stack-items get cut*
        [
            [ length number>string "(" " more items)" surround ] keep
            write-object nl
        ] dip
    ] when stack. ;

: datastack. ( datastack -- )
    display-stacks? get [
        [ nl "--- Data stack:" title. trimmed-stack. ] unless-empty
    ] [ drop ] if ;

: prompt. ( -- )
    current-vocab name>> auto-use? get [ " - auto" append ] when "( " " )" surround
    H{ { background T{ rgba f 1 0.7 0.7 1 } } } format bl flush ;

:: (listener) ( datastack -- )
    error-summary? get [ error-summary ] when
    visible-vars.
    datastack datastack.
    prompt.

    [
        read-quot [
            '[ datastack _ with-datastack ]
            [ call-error-hook datastack ]
            recover
        ] [ return ] if*
    ] [
        dup lexer-error?
        [ call-error-hook datastack ]
        [ rethrow ]
        if
    ] recover

    (listener) ;

PRIVATE>

SYMBOL: interactive-vocabs

{
    "accessors"
    "arrays"
    "assocs"
    "combinators"
    "compiler"
    "compiler.errors"
    "compiler.units"
    "continuations"
    "debugger"
    "definitions"
    "editors"
    "help"
    "help.apropos"
    "help.lint"
    "help.vocabs"
    "inspector"
    "io"
    "io.files"
    "io.pathnames"
    "kernel"
    "listener"
    "math"
    "math.order"
    "memory"
    "namespaces"
    "parser"
    "prettyprint"
    "see"
    "sequences"
    "slicing"
    "sorting"
    "stack-checker"
    "strings"
    "syntax"
    "tools.annotations"
    "tools.crossref"
    "tools.deprecation"
    "tools.destructors"
    "tools.disassembler"
    "tools.dispatch"
    "tools.errors"
    "tools.memory"
    "tools.profiler"
    "tools.test"
    "tools.threads"
    "tools.time"
    "vocabs"
    "vocabs.loader"
    "vocabs.refresh"
    "vocabs.hierarchy"
    "words"
    "scratchpad"
} interactive-vocabs set-global

: only-use-vocabs ( vocabs -- )
    clear-manifest
    [ vocab ] filter
    [
        vocab
        [ find-vocab-root not ]
        [ source-loaded?>> +done+ eq? ] bi or
    ] filter
    [ use-vocab ] each ;

: with-interactive-vocabs ( quot -- )
    [
        <manifest> manifest set
        "scratchpad" set-current-vocab
        interactive-vocabs get only-use-vocabs
        call
    ] with-scope ; inline

: listener ( -- )
    [ [ { } (listener) ] with-interactive-vocabs ] with-return ;

MAIN: listener
