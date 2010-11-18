
if v:version < 600
    syntax clear
elseif exists('b:current_syntax')
    finish
endif


syn case match
syn match skkComment '^;.*$'
syn match skkLine '^\S\+\s\+/.\+/$' contains=skkHiragana,skkCandidates,skkAnnotation
syn match skkHiragana '^\S\+' contained
syn match skkCandidates '\%\(^\S\+\s\+\)\@<=/.\+/$' contained contains=skkAnnotation
syn match skkAnnotation ';[^/]\+' contained



if v:version >= 508 || !exists("did_skk_syn_inits")
  if v:version < 508
    let did_skk_syn_inits = 1
    command -nargs=+ HiLink hi link <args>
  else
    command -nargs=+ HiLink hi def link <args>
  endif
  HiLink skkComment Comment
  HiLink skkHiragana Identifier
  HiLink skkCandidates Type
  HiLink skkAnnotation Comment
  delcommand HiLink
endif



let b:current_syntax = 'skk'
