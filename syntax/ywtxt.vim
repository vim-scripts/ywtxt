" mY oWn txt.
" Author: Yue Wu <ywupub@gmail.com>
" License: BSD

if exists("b:current_syntax")
  finish
endif

syntax match ywtxtheader '^\(\d\+\|#\)[[:digit:]#.]*\.\s.*$'
highlight default link ywtxtheader Title

syntax match ywtxtcomment '^%.*$'
highlight default link ywtxtcomment Comment
