" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


function! eskk#test#emulate_filter_keys(chars, ...) "{{{
    " Assumption: test case (a:chars) does not contain "(eskk:" string.

    let ret = ''
    for c in split(a:chars, '\zs')
        let ret = s:emulate_char(c, ret)
    endfor

    " For convenience.
    let clear_buftable = a:0 ? a:1 : 1
    if clear_buftable
        let buftable = eskk#get_buftable()
        call buftable.clear_all()
    endif

    return ret
endfunction "}}}

function! s:emulate_char(c, ret) "{{{
    let mapmode = eskk#mappings#get_map_modes()
    let c = a:c
    let ret = a:ret
    let r = eskk#filter(c)
    " NOTE: "\<Plug>" cannot be substituted by substitute().
    let r = s:remove_all_ctrl_chars(r, "\<Plug>")

    " Remove `<Plug>(eskk:_filter_redispatch_pre)` beforehand.
    let pre = ''
    if r =~# '(eskk:_filter_redispatch_pre)'
        let pre = maparg('<Plug>(eskk:_filter_redispatch_pre)', mapmode)
        let r = substitute(r, '(eskk:_filter_redispatch_pre)', '', '')
    endif

    " Remove `<Plug>(eskk:_filter_redispatch_post)` beforehand.
    let post = ''
    if r =~# '(eskk:_filter_redispatch_post)'
        let post = maparg('<Plug>(eskk:_filter_redispatch_post)', mapmode)
        let r = substitute(r, '(eskk:_filter_redispatch_post)', '', '')
    endif

    " Remove `<Plug>(eskk:_set_begin_pos)`.
    " it is <expr> and does not effect to result string.
    let r = substitute(r, '(eskk:_set_begin_pos)', '', 'g')

    " Expand some <expr> <Plug> mappings.
    let r = substitute(
    \   r,
    \   '(eskk:expr:[^()]\+)',
    \   '\=eval(eskk#util#key2char(maparg("<Plug>".submatch(0), mapmode)))',
    \   'g'
    \)

    " Expand normal <Plug> mappings.
    let r = substitute(
    \   r,
    \   '(eskk:[^()]\+)',
    \   '\=eskk#util#key2char(maparg("<Plug>".submatch(0), mapmode))',
    \   'g'
    \)

    let [r, ret] = s:emulate_backspace(r, ret)

    " Handle `<Plug>(eskk:_filter_redispatch_pre)`.
    if pre != ''
        let _ = eval(pre)
        let _ = s:remove_all_ctrl_chars(r, "\<Plug>")
        let [_, ret] = s:emulate_filter_char(_, ret)
        let _ = substitute(
        \   _,
        \   '(eskk:[^()]\+)',
        \   '\=eskk#util#key2char(maparg("<Plug>".submatch(0), mapmode))',
        \   'g'
        \)
        let ret .= _
        let ret .= maparg(eval(pre), mapmode)
    endif

    " Handle rewritten text.
    let ret .= r

    " Handle `<Plug>(eskk:_filter_redispatch_post)`.
    if post != ''
        let _ = eval(post)
        let _ = s:remove_all_ctrl_chars(_, "\<Plug>")
        let [_, ret] = s:emulate_filter_char(_, ret)
        let _ = substitute(
        \   _,
        \   '(eskk:[^()]\+)',
        \   '\=eskk#util#key2char(maparg("<Plug>".submatch(0), mapmode))',
        \   'g'
        \)
        let ret .= _
    endif

    return ret
endfunction "}}}
function! s:emulate_backspace(r, ret) "{{{
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
    return [r, ret]
endfunction "}}}
function! s:emulate_filter_char(r, ret) "{{{
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

function! s:remove_all_ctrl_chars(s, ctrl_char) "{{{
    let s = a:s
    while 1
        let [s, pos] = s:remove_ctrl_char(s, a:ctrl_char)
        if pos == -1
            break
        endif
    endwhile
    return s
endfunction "}}}
function! s:remove_ctrl_char(s, ctrl_char) "{{{
    let s = a:s
    let pos = stridx(s, a:ctrl_char)
    if pos != -1
        let before = strpart(s, 0, pos)
        let after  = strpart(s, pos + strlen(a:ctrl_char))
        let s = before . after
    endif
    return [s, pos]
endfunction "}}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
