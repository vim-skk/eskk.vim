" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


function! eskk#test#emulate_filter_keys(chars, ...) abort "{{{
    let ret = ''
    for c in s:each_char(a:chars)
        let ret = s:emulate_char(c, ret)
    endfor

    let clear_preedit = a:0 ? a:1 : 1
    if clear_preedit
        let preedit = eskk#get_preedit()
        call preedit.clear_all()
    endif

    return ret
endfunction "}}}

function! s:each_char(chars) abort "{{{
    let r = split(a:chars, '\zs')
    let r = s:aggregate_backspace(r)
    return r
endfunction "}}}
function! s:aggregate_backspace(list) abort "{{{
    let list = a:list
    let pos = -1
    while 1
        let pos = index(list, "\x80", pos + 1)
        if pos is -1
            break
        endif
        if list[pos+1] ==# 'k' && list[pos+2] ==# 'b'
            unlet list[pos : pos+2]
            call insert(list, "\<BS>", pos)
        endif
    endwhile
    return list
endfunction "}}}
function! s:remove_ctrl_char(s, ctrl_char) abort "{{{
    let s = a:s
    let pos = stridx(s, a:ctrl_char)
    if pos != -1
        let before = strpart(s, 0, pos)
        let after  = strpart(s, pos + strlen(a:ctrl_char))
        let s = before . after
    endif
    return [s, pos]
endfunction "}}}

function! s:emulate_char(c, ret) abort "{{{
    let c = a:c
    let ret = a:ret
    let r = eskk#filter(c)
    let ret = s:emulate_backspace(r, ret)
    return ret
endfunction "}}}
function! s:emulate_backspace(r, ret) abort "{{{
    let r = a:r
    let ret = a:ret
    for bs in ["\<BS>", "\<C-h>"]
        while 1
            let [r, pos] = s:remove_ctrl_char(r, bs)
            if pos ==# -1
                break
            endif
            if pos ==# 0
                if ret == ''
                    let r = bs . r
                    break
                else
                    let ret = eskk#util#mb_chop(ret)
                endif
            else
                let before = strpart(r, 0, pos)
                let after = strpart(r, pos)
                let before = eskk#util#mb_chop(before)
                let r = before . after
            endif
        endwhile
    endfor
    " Handle rewritten text.
    return ret . r
endfunction "}}}
function! s:emulate_filter_char(r, ret) abort "{{{
    let r = a:r
    let ret = a:ret
    while 1
        let pat = '(eskk:filter:\([^()]*\))'.'\C'
        let m = matchlist(r, pat)
        if empty(m)
            break
        endif
        let char = m[1]
        let r = substitute(r, pat, '', '')
        let _ = eskk#test#emulate_filter_keys(char, 0)
        let [_, ret] = s:emulate_backspace(_, ret)
        let r .= _
    endwhile
    return [r, ret]
endfunction "}}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
