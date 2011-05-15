" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}



function! s:run()
    let t = eskk#table#new(tempname(), 'rom_to_hira')
    call t.add_map('va', 'ゔぁ')
    call t.add_map('vi', 'ゔぃ')
    call t.add_map('vu', 'ゔ')
    call t.add_map('ve', 'ゔぇ')
    call t.add_map('vo', 'ゔぉ')
    call t.add_map('z ', '　')


    let NOT_FOUND = []

    " "za" is parent table (s:DataTable, "rom_to_hira")'s mapping.
    " "z " is t (s:DiffTable, tempname())'s mapping.
    "
    " t can look up "za" correctly?

    Ok t.has_map('z '), 'has "z " map'
    Ok t.has_map('za'), 'has "za" map'
    Isnt t.get_map('z ', NOT_FOUND), NOT_FOUND, 'has "z " map'
    Isnt t.get_map('za', NOT_FOUND), NOT_FOUND, 'has "za" map'

    Ok !empty(t.get_candidates('z ', 999)), 'has "z " candidates'
    Ok !empty(t.get_candidates('za', 999)), 'has "za" candidates'
    Ok t.has_candidates('z '), 'has "z " candidates'
    Ok t.has_candidates('za'), 'has "za" candidates'
    Ok t.has_n_candidates('z ', 1), 'has "z " map'
    Ok t.has_n_candidates('za', 1), 'has "za" map'

    try
        Ok t.has_n_candidates('z ', 0), 'has "z " map'
        Ok 0, 't.has_n_candidates() - raise error for invalid argument'
    catch
        Ok 1, 't.has_n_candidates() - raise error for invalid argument'
    endtry
endfunction

call s:run()
Done


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
