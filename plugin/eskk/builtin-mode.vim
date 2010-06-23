" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/eskk.vim' about the license.


runtime! plugin/eskk.vim

" g:eskk_disable {{{
if g:eskk_disable
    finish
endif
" }}}
" Load Once {{{
if exists('g:loaded_eskk_builtin_mode') && g:loaded_eskk_builtin_mode
    finish
endif
let g:loaded_eskk_builtin_mode = 1
" }}}
" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

" Register builtin-modes. {{{

" 'ascii' mode {{{
call eskk#register_mode('ascii')
let dict = eskk#get_mode_structure('ascii')

function! dict.filter(stash)
    if eskk#is_special_lhs(a:stash.char, 'mode:ascii:to-hira')
        call eskk#set_mode('hira')
    else
        if has_key(g:eskk_mode_use_tables, 'ascii')
            if !has_key(self.sandbox, 'table')
                let self.sandbox.table = eskk#table#new(g:eskk_mode_use_tables.ascii)
            endif
            let a:stash.return = self.sandbox.table.get_map_to(a:stash.char, a:stash.char)
        else
            let a:stash.return = a:stash.char
        endif
    endif
endfunction

call eskk#validate_mode_structure('ascii')
" }}}

" 'zenei' mode {{{
call eskk#register_mode('zenei')
let dict = eskk#get_mode_structure('zenei')

function! dict.filter(stash)
    if eskk#is_special_lhs(a:stash.char, 'mode:zenei:to-hira')
        call eskk#set_mode('hira')
    else
        if !has_key(self.sandbox, 'table')
            let self.sandbox.table = eskk#table#new(g:eskk_mode_use_tables.zenei)
        endif
        let a:stash.return = self.sandbox.table.get_map_to(a:stash.char, a:stash.char)
    endif
endfunction

call eskk#validate_mode_structure('zenei')
" }}}

" 'hira' mode {{{
call eskk#register_mode('hira')
let dict = eskk#get_mode_structure('hira')

function! dict.filter(...)
    return call('eskk#mode#builtin#asym_filter', a:000 + [g:eskk_mode_use_tables.hira])
endfunction

call eskk#validate_mode_structure('hira')
" }}}

" 'kata' mode {{{
call eskk#register_mode('kata')
let dict = eskk#get_mode_structure('kata')

function! dict.filter(...)
    return call('eskk#mode#builtin#asym_filter', a:000 + [g:eskk_mode_use_tables.kata])
endfunction

call eskk#validate_mode_structure('kata')
" }}}

" 'hankata' mode {{{
call eskk#register_mode('hankata')
let dict = eskk#get_mode_structure('hankata')

function! dict.filter(...)
    return call('eskk#mode#builtin#asym_filter', a:000 + [g:eskk_mode_use_tables.hankata])
endfunction

call eskk#validate_mode_structure('hankata')
" }}}

unlet dict

" }}}

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
