" mY oWn txt.
" Author: Yue Wu <ywupub@gmail.com>
" License: BSD

if exists("b:current_syntax")
  finish
endif
scriptencoding utf-8

call Ywtxt_SearchHeadingPat()

syntax match ywtxt_title /\%^\_.\{-}\zs\s\+\zs\S.*\ze\s\+$/ contains=ALL
highlight default link ywtxt_title Title

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
  syntax match ywtxt_Fig '^\s*\%(\cFig\%(\.\|ure\)\|图\)\s\%(#\|\d\+\)\.\s\s'
  syntax match ywtxt_Tab '^\s*\%(\cTable\|表\)\s\%(#\|\d\+\)\.\s\s'
else " For mom window
  syntax match ywtxt_Fig '^\s*\%(\cFig\%(\.\|ure\)\|图\)\s\%(#\|\d\+\)\.\s'
  syntax match ywtxt_Tab '^\s*\%(\cTable\|表\)\s\%(#\|\d\+\)\.\s'
endif
highlight default link ywtxt_Fig Comment
highlight default link ywtxt_Tab Comment

syntax match ywtxt_bold '\%(\s\|^\)\zs\*\S[^*]*\S\*\ze\%(\s\|$\)'
highlight ywtxt_bold term=bold cterm=bold gui=bold

syntax match ywtxt_underline '\%(\s\|^\)\zs_\S[^_]*\S_\ze\%(\s\|$\)'
highlight ywtxt_underline term=underline cterm=underline gui=underline

syntax match ywtxt_italic '\%(\s\|^\)\zs/\S[^/]*\S/\ze\%(\s\|$\)'
highlight ywtxt_italic term=italic cterm=italic gui=italic

call Ywtxt_Syntax_HeadingsPat()
call Ywtxt_highlightheadings()

let b:current_syntax = "ywtxt"

" vim: ts=2 sw=2 et
