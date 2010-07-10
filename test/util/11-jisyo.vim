" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


function! s:run()
    if !(exists('$ESKK_TEST_DICTIONARY') && $ESKK_TEST_DICTIONARY != '')
        Skip 'Set $ESKK_TEST_DICTIONARY to test.'
    endif

    " Set up buftable.
    let buftable = eskk#buftable#new()
    let curbufstr = buftable.get_current_buf_str()

    call curbufstr.set_rom_str('')
    call curbufstr.set_filter_str('あさ')

    " Set up dictionary.
    let dict = eskk#dictionary#new($ESKK_TEST_DICTIONARY)
    VarDump dict.refer(buftable)
endfunction


call s:run()
Done


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

