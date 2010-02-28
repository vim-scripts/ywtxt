" mY oWn txt.
" Author: Yue Wu <ywupub@gmail.com>
" License: BSD

if exists("b:current_syntax")
  finish
endif

syntax match ywtxt_comment '\[\(\k\+,\s*\)*\(\k\+\)\]'
highlight default link ywtxt_comment Comment

syntax match ywtxt_comment '^%.*$'
highlight default link ywtxt_comment Comment

syntax match ywtxt_Fig '^\s*Fig\.\s\(#\|\d\+\)\.\s'
highlight default link ywtxt_Fig Comment
syntax match ywtxt_Tab '^\s*Table\s\(#\|\d\+\)'
highlight default link ywtxt_Tab Comment

syntax match ywtxt_bold '\%(\s\|^\)\zs\*[^[:blank:]*]\+\*\ze\(\s\|$\)'
highlight ywtxt_bold term=bold cterm=bold gui=bold

syntax match ywtxt_underline '\%(\s\|^\)\zs_[^[:blank:]_]\+_\ze\(\s\|$\)'
highlight ywtxt_underline term=underline cterm=underline gui=underline

syntax match ywtxt_italic '\%(\s\|^\)\zs/[^[:blank:]/]\+/\ze\(\s\|$\)'
highlight ywtxt_italic term=italic cterm=italic gui=italic

for i in range(1,10)
  execute 'syntax match ywtxt_header'.i.' /^\(\d\+\.\|#\.\)\{'.i.'}\s.*$/ contains=ALL'
endfor
if &background == "dark"
  highlight ywtxt_header0 ctermfg=blue cterm=bold guifg=LightSkyBlue gui=bold
  highlight ywtxt_header1 ctermfg=yellow cterm=bold guifg=LightGoldenrod gui=bold
  highlight ywtxt_header2 ctermfg=cyan cterm=bold guifg=Cyan1 gui=bold
  highlight ywtxt_header3 ctermfg=red cterm=bold guifg=red1 gui=bold
  highlight ywtxt_header4 ctermfg=green cterm=bold guifg=PaleGreen gui=bold
  highlight ywtxt_header5 ctermfg=magenta cterm=bold guifg=Aquamarine gui=bold
  highlight ywtxt_header6 ctermfg=blue cterm=bold guifg=LightSteelBlue gui=bold
  highlight ywtxt_header7 ctermfg=green cterm=bold guifg=LightSalmon gui=bold
  highlight ywtxt_header8 ctermfg=blue cterm=bold guifg=LightSkyBlue gui=bold
  highlight ywtxt_header9 ctermfg=yellow cterm=bold guifg=LightGoldenrod gui=bold
else
  highlight ywtxt_header0 ctermfg=blue cterm=bold guifg=Blue1 gui=bold
  highlight ywtxt_header1 ctermfg=yellow cterm=bold guifg=DarkGoldenrod gui=bold
  highlight ywtxt_header2 ctermfg=cyan cterm=bold guifg=Purple gui=bold
  highlight ywtxt_header3 ctermfg=red cterm=bold guifg=red gui=bold
  highlight ywtxt_header4 ctermfg=green cterm=bold guifg=ForestGreen gui=bold
  highlight ywtxt_header5 ctermfg=magenta cterm=bold guifg=CadetBlue gui=bold
  highlight ywtxt_header6 ctermfg=blue cterm=bold guifg=Orchid gui=bold
  highlight ywtxt_header7 ctermfg=green cterm=bold guifg=RosyBrown gui=bold
  highlight ywtxt_header8 ctermfg=blue cterm=bold guifg=Blue1 gui=bold
  highlight ywtxt_header9 ctermfg=yellow cterm=bold guifg=DarkGoldenrod gui=bold
endif

let b:current_syntax = "yworg"

" vim: ts=2 sw=2 et
