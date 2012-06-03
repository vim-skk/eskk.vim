" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}



function! s:run()
    for [fn, args, regexp] in [
    \   ['eskk#dictionary#look_up_error',
    \       ['could not look up my clarinet'],
    \       '^eskk: dictionary look up error: could not look up my clarinet'],
    \   ['eskk#preedit#invalid_henkan_phase_value_error',
    \       [1],
    \       "^eskk: invalid henkan phase value '1'"],
    \   ['eskk#dictionary#parse_error',
    \       ['duplicated candidates'],
    \       '^eskk: SKK dictionary parse error: duplicated candidates'],
    \   ['eskk#map#cmd_eskk_map_invalid_args',
    \       ['unknown option --foo'],
    \       '^eskk: :EskkMap argument parse error: unknown option --foo'],
    \   ['eskk#table#invalid_arguments_error',
    \       ['foo'],
    \       '^eskk: eskk#table#new() received invalid arguments '
    \           . '(table name: foo)'],
    \   ['eskk#table#extending_myself_error',
    \       ['foo'],
    \       "^eskk: table 'foo' derived from itself"]
    \]
        Like call(fn, args), regexp,
        \   'check the format: '
        \   . fn . '(' . join(map(args, 'string(v:val)'), ',') . ')'
    endfor
endfunction

call s:run()
Done


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
