" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

" Functions {{{
let s:dict = {
\   'okuri_nasi_lnum': 0,
\   'okuri_ari_lnum': 0,
\   'dict_bufnr': -1,
\   'dict_path': [],
\}


function! eskk#dictionary#new(dict_path) "{{{
    if type(a:dict_path) == type([])
        let dict_path = map(copy(a:dict_path), 'expand(v:val)')
    else
        return eskk#dictionary#new([a:dict_path])
    endif
    return extend(
    \   deepcopy(s:dict),
    \   {'dict_path': dict_path},
    \)
endfunction "}}}


function! s:dict.henkan(key, okuri) dict "{{{
    Decho 'henkan'
    return self.search_buf(
    \   self.get_dict_bufnr(),
    \   a:key,
    \   a:okuri,
    \   1000
    \)
endfunction "}}}

" This was originally from s:SkkGetJisyoBuf().
function! s:dict.search_buf(bufnr, key, okuri, limit) dict "{{{
    Decho 'search_buf'
    return eskk#util#call_on_buffer(
    \   a:bufnr,
    \   eskk#util#get_local_func('dispatch_search', s:SID()),
    \   [self, a:key, a:okuri, a:limit]
    \)
endfunction "}}}
function! s:SID() "{{{
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction "}}}
function! s:dispatch_search(this, key, okuri, limit) "{{{
    Decho 'dispatch_search'
    if a:limit == 0
        return a:this.search_linear(a:key, a:okuri)
    else
        return a:this.search_binary(a:key, a:okuri, a:limit)
    endif
endfunction "}}}

" リニアサーチ ソートしていないファイル用
" 送りなしエントリの先頭に移動して送りありなら先頭方向に
" 送りなしなら末尾方向に検索する。
function! s:dict.search_linear(key, okuri) dict "{{{
  if self.okuri_nasi_lnum
    if a:okuri != ""
      let flag = "bW"
      exe "normal! " . self.okuri_nasi_lnum . "G0"
    else
      let flag = "W"
      exe "normal! " . self.okuri_nasi_lnum . "G$"
    endif
  else
    let flag = "W"
    exe "normal! 1G0"
  endif
  let key = escape(a:key, '$.*\[]') . '\m'
  return substitute(getline(search(key, flag)), key, '', '')
endfunction "}}}

" バイナリサーチ ソート済ファイル用
" 送りありエントリは降順に、送りなしエントリは昇順にソートされている必要がある。
" 検索範囲が limit 以下になるまで二分検索を行い、その後、リニアサーチする。
" search() が最後まで検索してしまうため最悪の場合は SkkSearchLinear より遅い。
function! s:dict.search_binary(key, okuri, limit) dict "{{{
    if self.okuri_nasi_lnum == 0
        return self.search_linear(a:key, a:okuri)
    endif
    let key = a:key
    if a:okuri
        let min = self.okuri_ari_lnum + 1
        let max = self.okuri_nasi_lnum - 1
    else
        let min = self.okuri_nasi_lnum + 1
        let max = line("$")
    endif
    while max - min > a:limit
        let mid = (max + min) / 2
        let line = getline(mid)
        if key >=# line
            if a:okuri
                let max = mid
            else
                let min = mid
            endif
        else
            if a:okuri
                let min = mid
            else
                let max = mid
            endif
        endif
    endwhile
    if a:okuri
        let flag = "bW"
        let max = max + 1	" max 行を含めるため
        exe "normal! " . max . "G0"
    else
        let flag = "W"
        let min = min - 1	" min 行を含めるため
        exe "normal! " . min . "G$"
    endif
    let key = escape(a:key, '$.*\[]') . '\m'
    return substitute(getline(search(key, flag)), key, '', '')
endfunction "}}}

" This was originally from s:SkkGetJisyoBuf().
function! s:dict.get_dict_bufnr() dict "{{{
    if self.dict_bufnr !=# -1
        if bufexists(self.dict_bufnr)
            return self.dict_bufnr
        endif
        throw eskk#internal_error('eskk: dict', 'Someone deleted JISYO buffer!!')
    endif

    " Set up self.dict_bufnr.
    let self.dict_buffer_name = tempname()
    silent execute 'badd' self.dict_buffer_name
    let self.dict_bufnr = bufnr(self.dict_buffer_name)

    " Load dictionary buffers to self.dict_bufnr
    for dict_path in self.dict_path
        if filereadable(dict_path)
            call eskk#util#setbufline(self.dict_bufnr, 1, readfile(dict_path))
        endif
    endfor

    " 1行目に okuri-ari entries. があると見つけられないためこの順序にした。
    let self.okuri_nasi_lnum = search("^;; okuri-nasi entries.$", "W")
    let self.okuri_ari_lnum = search("^;; okuri-ari entries.$", "bW")
    if self.okuri_nasi_lnum == 0 && self.okuri_ari_lnum == 0 && line("$") == 1
        call eskk#util#setbufline(self.dict_bufnr, 1, [';; okuri-ari entries.', ';; okuri-nasi entries.'])
        let self.okuri_ari_lnum = 1
        let self.okuri_nasi_lnum = 2
    endif

    setlocal nobuflisted buftype=nowrite bufhidden=hide
    return self.dict_bufnr
endfunction "}}}


lockvar s:dict
" }}}

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
