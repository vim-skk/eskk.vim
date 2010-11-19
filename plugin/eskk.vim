" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'doc/eskk.txt'.

" Load Once {{{
if exists('g:loaded_eskk') && g:loaded_eskk
    finish
endif
let g:loaded_eskk = 1
" }}}
" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

" Check if prereq libs are installed.
function! s:check_if_prereq_libs_are_installed()
    echohl ErrorMsg
    try
        if globpath(&rtp, 'autoload/cul/ordered_set.vim') == ''
            echomsg 'autoload/cul/ordered_set.vim is not installed.'
            return 0
        endif
        if globpath(&rtp, 'autoload/savemap.vim') == ''
            echomsg 'autoload/savemap.vim is not installed.'
            return 0
        endif

        return 1    " All libs are installed!
    finally
        echohl None
    endtry
endfunction "}}}
if !s:check_if_prereq_libs_are_installed()
    finish
endif

" Mappings {{{

noremap! <expr> <Plug>(eskk:enable)     eskk#enable()
lnoremap <expr> <Plug>(eskk:enable)     eskk#enable()

noremap! <expr> <Plug>(eskk:disable)    eskk#disable()
lnoremap <expr> <Plug>(eskk:disable)    eskk#disable()

noremap! <expr> <Plug>(eskk:toggle)     eskk#toggle()
lnoremap <expr> <Plug>(eskk:toggle)     eskk#toggle()

nnoremap        <Plug>(eskk:save-dictionary) :<C-u>EskkUpdateDictionary<CR>

nnoremap <silent> <Plug>(eskk:alpha-t) :<C-u>call eskk#jump_one_char('t')<CR>
nnoremap <silent> <Plug>(eskk:alpha-f) :<C-u>call eskk#jump_one_char('f')<CR>
nnoremap <silent> <Plug>(eskk:alpha-T) :<C-u>call eskk#jump_one_char('T')<CR>
nnoremap <silent> <Plug>(eskk:alpha-F) :<C-u>call eskk#jump_one_char('F')<CR>
nnoremap <silent> <Plug>(eskk:alpha-,) :<C-u>call eskk#repeat_last_jump(',')<CR>
nnoremap <silent> <Plug>(eskk:alpha-;) :<C-u>call eskk#repeat_last_jump(';')<CR>

noremap! <expr> <Plug>(eskk:_set_begin_pos) [eskk#get_buftable().set_begin_pos('.'), ''][1]


" Global variables
if !exists('g:eskk#no_default_mappings')
    let g:eskk#no_default_mappings = 0
endif
if !exists('g:eskk#dont_map_default_if_already_mapped')
    let g:eskk#dont_map_default_if_already_mapped = 1
endif


if !g:eskk#no_default_mappings
    function! s:do_map(rhs, mode)
        let map_default_even_if_already_mapped = !g:eskk#dont_map_default_if_already_mapped
        return
        \   map_default_even_if_already_mapped
        \   || !hasmapto(a:rhs, a:mode)
    endfunction

    if s:do_map('<Plug>(eskk:toggle)', 'i')
        silent! imap <unique> <C-j>   <Plug>(eskk:toggle)
    endif
    if s:do_map('<Plug>(eskk:toggle)', 'c')
        silent! cmap <unique> <C-j>   <Plug>(eskk:toggle)
    endif
    if s:do_map('<Plug>(eskk:toggle)', 'l')
        silent! lmap <unique> <C-j>   <Plug>(eskk:toggle)
    endif

    delfunc s:do_map
endif

" }}}

" Commands {{{

command!
\   -nargs=+
\   EskkMap
\   call eskk#mappings#_cmd_eskk_map(<q-args>)


command!
\   -bar
\   EskkForgetRegisteredWords
\   call s:cmd_forget_registered_words()

function! s:cmd_forget_registered_words()
    call eskk#get_skk_dict().forget_all_words()
endfunction


command!
\   -bar -bang
\   EskkUpdateDictionary
\   call s:cmd_update_dictionary(<bang>0)

function! s:cmd_update_dictionary(silent)
    let silent = a:0 ? a:1 : 0
    let dict = eskk#get_skk_dict()
    execute (silent ? 'silent' : '') 'call dict.update_dictionary()'
endfunction

" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
