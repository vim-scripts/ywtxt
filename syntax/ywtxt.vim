" mY oWn txt.
" Author: Yue Wu <ywupub@gmail.com>
" License: BSD

if exists("b:current_syntax") && b:current_syntax == 'ywtxt'
  finish
endif
scriptencoding utf-8

call Ywtxt_SearchHeadingPat()

syntax match ywtxt_title /\%^\s\+\S.*\s$/ contains=ALL
highlight default link ywtxt_title Title

syntax match ywtxt_footnote /^\s*\%(footnote\|注\):/ contained
highlight default link ywtxt_footnote Comment

syntax keyword ywtxt_done DONE
highlight default link ywtxt_done Comment
syntax keyword ywtxt_todo FIXME TODO
highlight default link ywtxt_todo Todo
syntax keyword ywtxt_note note Note NOTE note: Note: NOTE: Notes Notes: 注意
highlight default link ywtxt_note Todo

syntax match ywtxt_ref '\^\[[^]]*\]'
highlight default link ywtxt_ref Comment
syntax match ywtxt_url '\*\[[^]]*\]'
highlight default link ywtxt_url Identifier
syntax match ywtxt_anchor '\*\@<!\[#[^]]*\]'
highlight default link ywtxt_anchor String

syntax match ywtxt_comment '^\s*%.*$' contains=ALL
highlight default link ywtxt_comment Comment

if match(bufname(""), '_.*_TOC_') == -1 " For mom window
  syntax match ywtxt_Fig '^\s*\%(\cFig\%(\.\|ure\)\|图\)\s\%(#\|\d\+\)\%(\|-\%(#\|\d\+\)\)\.\s\s'
  syntax match ywtxt_Tab '^\s*\%(\cTable\|表\)\s\%(#\|\d\+\)\.\s\s'
else " For mom window
  syntax match ywtxt_Fig '^\s*\%(\cFig\%(\.\|ure\)\|图\)\s\%(#\|\d\+\)\%(\|-\%(#\|\d\+\)\)\.\s'
  syntax match ywtxt_Tab '^\s*\%(\cTable\|表\)\s\%(#\|\d\+\)\.\s'
endif
highlight default link ywtxt_Fig Comment
highlight default link ywtxt_Tab Comment

" TODO
" syntax match ywtxt_boldl contained '\%(\s\|^\)\zs\*\ze\S[^*]*\S\*\%(\s\|$\)'
" syntax match ywtxt_boldr contained '\%(\s\|^\)\*\S[^*]*\S\zs\*\ze\%(\s\|$\)'
" highlight default link ywtxt_boldl Ignore
" highlight default link ywtxt_boldr Ignore
" syntax match ywtxt_bold '\%(\s\|^\)\*\zs\S[^*]*\S\ze\*\%(\s\|$\)' contains=ywtxt_boldl,ywtxt_boldr
syntax match ywtxt_bold '\%(\s\|^\|[^\x00-\xff]\)\zs\*[^*[:blank:][:punct:]，。!:“”；‘’]\+\*\ze\%([[:punct:]]\|\s\|$\|[^\x00-\xff]\)'
highlight ywtxt_bold term=bold cterm=bold gui=bold

syntax match ywtxt_underline '\%(\s\|^\|[^\x00-\xff]\)\zs_[^_[:blank:][:punct:]，。!:“”；‘’]\+_\ze\%([[:punct:]]\|\s\|$\|[^\x00-\xff]\)'
highlight ywtxt_underline term=underline cterm=underline gui=underline

syntax match ywtxt_italic '\%(\s\|^\|[^\x00-\xff]\)\zs/[^/[:blank:][:punct:]，。!:“”；‘’]\+/\ze\%([[:punct:]]\|\s\|$\|[^\x00-\xff]\)'
highlight ywtxt_italic term=italic cterm=italic gui=italic

call Ywtxt_Syntax_HeadingsPat()
call Ywtxt_highlightheadings()

let b:current_syntax = "ywtxt"

" vim: ts=2 sw=2 et
