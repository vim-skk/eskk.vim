
if v:version < 600
    syntax clear
elseif exists('b:current_syntax')
    finish
endif


syn case match
syn match SkkComment '^;.*$'
syn match SkkLine '^\S\+\s\+/.\+/$' contains=SkkHiragana,SkkCandidates,SkkAnnotation
syn match SkkHiragana '^\S\+' contained
syn match SkkCandidates '\%\(^\S\+\s\+\)\@<=/.\+/$' contained contains=SkkAnnotation
syn match SkkAnnotation ';[^/]\+' contained



if v:version >= 508 || !exists("did_skk_syn_inits")
  if v:version < 508
    let did_skk_syn_inits = 1
    command -nargs=+ HiLink hi link <args>
  else
    command -nargs=+ HiLink hi def link <args>
  endif
  HiLink SkkComment Comment
  HiLink SkkHiragana Identifier
  HiLink SkkCandidates Type
  HiLink SkkAnnotation Comment
  delcommand HiLink
endif



let b:current_syntax = 'skk'
