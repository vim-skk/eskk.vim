

" This was originally from s:SkkGetJisyoBuf().
function! s:dict.search_buf(bufnr, key, okuri, limit) dict "{{{
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
