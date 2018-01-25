" vim:foldmethod=marker:fen:sw=4:sts=4
scriptencoding utf-8


" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


function! neocomplete#sources#eskk#define() abort "{{{
    return s:source
endfunction"}}}

let s:source = {
            \ 'name': 'eskk',
            \ 'kind': 'manual',
            \ 'min_pattern_length': 0,
            \ 'is_volatile': 1,
            \ 'matchers': ['matcher_nothing'],
            \ 'sorters': [],
            \}

function! s:source.get_complete_position(context) abort "{{{
    if !eskk#is_enabled()
                \ || eskk#get_preedit().get_henkan_phase() ==#
                \             g:eskk#preedit#PHASE_NORMAL
                \ || a:context['input'] =~# '\w$'
        return -1
    endif
    return eskk#complete#eskkcomplete(1, '')
endfunction"}}}

function! s:source.gather_candidates(context) abort "{{{
    return eskk#complete#eskkcomplete(0, a:context.complete_str)
endfunction"}}}

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
