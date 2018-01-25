" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}



function! s:run()
  try
    call eskk#table#new('foo', 'foo')
    Ok 0, 'it should throw an exception (eskk#table#extending_myself_error()'
  catch /eskk: table.*derived from itself/
    Ok 1, 'it should throw an exception (eskk#table#extending_myself_error()'
  endtry

  try
    call eskk#table#new('foo', 'bar')
    Ok 1, 'it should NOT throw an exception (eskk#table#extending_myself_error()'
  catch /eskk: table.*derived from itself/
    Ok 0, 'it should NOT throw an exception (eskk#table#extending_myself_error()'
  endtry

  try
    call eskk#table#new('rom_to_hira', 'rom_to_hira')
    Ok 0, 'it should throw an exception (eskk#table#extending_myself_error()'
  catch /eskk: table.*derived from itself/
    Ok 1, 'it should throw an exception (eskk#table#extending_myself_error()'
  endtry

  try
    call eskk#table#new('rom_to_hira', 'bar')
    Ok 1, 'it should NOT throw an exception (eskk#table#extending_myself_error()'
  catch /eskk: table.*derived from itself/
    Ok 0, 'it should NOT throw an exception (eskk#table#extending_myself_error()'
  endtry

  try
    call eskk#table#new('bar', 'rom_to_hira')
    Ok 1, 'it should NOT throw an exception (eskk#table#extending_myself_error()'
  catch /eskk: table.*derived from itself/
    Ok 0, 'it should NOT throw an exception (eskk#table#extending_myself_error()'
  endtry
endfunction

call s:run()
Done


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
