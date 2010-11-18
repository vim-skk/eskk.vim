
if v:version < 600
    syntax clear
elseif exists('b:current_syntax')
    finish
endif


syn case match
syn match skkdictComment '^;.*$'
syn match skkdictLine '^\S\+\s\+/.\+/$' contains=skkdictHiragana,skkdictCandidates,skkdictAnnotation
syn match skkdictHiragana '^\S\+' contained
syn match skkdictCandidates '\%\(^\S\+\s\+\)\@<=/.\+/$' contained contains=skkdictAnnotation
syn match skkdictAnnotation ';[^/]\+' contained



if v:version >= 508 || !exists("did_skkdict_syn_inits")
  if v:version < 508
    let did_skkdict_syn_inits = 1
    command -nargs=+ HiLink hi link <args>
  else
    command -nargs=+ HiLink hi def link <args>
  endif
  HiLink skkdictComment Comment
  HiLink skkdictHiragana Identifier
  HiLink skkdictCandidates Type
  HiLink skkdictAnnotation Comment
  delcommand HiLink
endif



let b:current_syntax = 'skkdict'
