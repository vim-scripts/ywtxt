" mY oWn txt.
" Author: Yue Wu <ywupub@gmail.com>
" License: BSD

if exists("b:current_syntax")
  finish
endif

syntax keyword ywtxt_done DONE
highlight default link ywtxt_done Comment
syntax keyword ywtxt_todo FIXME TODO
highlight default link ywtxt_todo Todo
syntax keyword ywtxt_note note Note NOTE note: Note: NOTE: Notes Notes: 注意
highlight default link ywtxt_note Todo

syntax match ywtxt_ref '\^\[[^]]*\]'
highlight default link ywtxt_ref Comment

syntax match ywtxt_comment '^\s*%.*$' contains=ALL
highlight default link ywtxt_comment Comment

syntax match ywtxt_Fig '^\s*Fig\(\.\|ure\)\s\(#\|\d\+\)\.\s'
highlight default link ywtxt_Fig Comment
syntax match ywtxt_Tab '^\s*Table\s\(#\|\d\+\)'
highlight default link ywtxt_Tab Comment

syntax match ywtxt_bold '\%([[:punct:]]\|\s\|^\)\zs\*[^[:blank:]*]\+\*\ze\([[:punct:]]\|\s\|$\)'
highlight ywtxt_bold term=bold cterm=bold gui=bold

syntax match ywtxt_underline '\%([[:punct:]]\|\s\|^\)\zs_[^[:blank:]_]\+_\ze\([[:punct:]]\|\s\|$\)'
highlight ywtxt_underline term=underline cterm=underline gui=underline

syntax match ywtxt_italic '\%([[:punct:]]\|\s\|^\)\zs/[^[:blank:]/]\+/\ze\([[:punct:]]\|\s\|$\)'
highlight ywtxt_italic term=italic cterm=italic gui=italic

syntax match ywtxt_heading0 /^\%(#\|\d\+\)\.\s\+.*/ contains=ALL
if match(bufname(""), '_.*_TOC_') == 0 " For toc window
  for i in range(1,10)
    execute 'syntax match ywtxt_heading'.i.' /^\s\{' . (2 * (i - 1)) . '\}\%(\%(#\|\d\+\)\.\)\{'.(i - 1).'}\%(#\|\d\+\)\s.*/ contains=CONTAINED'
  endfor
else " For mom window
  call Ywtxt_FindSnipft()
  for i in range(1,10)
    execute 'syntax match ywtxt_heading'.i.' /^\%(\%(#\|\d\+\)\.\)\{' . (i - 1) . '}\%(#\|\d\+\)\s\{2}.*/ contains=CONTAINED'
  endfor
endif
if &background == "dark"
  highlight ywtxt_heading1 ctermfg=blue cterm=bold guifg=LightSkyBlue gui=bold
  highlight ywtxt_heading2 ctermfg=yellow cterm=bold guifg=LightGoldenrod gui=bold
  highlight ywtxt_heading3 ctermfg=cyan cterm=bold guifg=Cyan1 gui=bold
  highlight ywtxt_heading4 ctermfg=red cterm=bold guifg=red1 gui=bold
  highlight ywtxt_heading5 ctermfg=green cterm=bold guifg=PaleGreen gui=bold
  highlight ywtxt_heading6 ctermfg=magenta cterm=bold guifg=Aquamarine gui=bold
  highlight ywtxt_heading7 ctermfg=blue cterm=bold guifg=LightSteelBlue gui=bold
  highlight ywtxt_heading8 ctermfg=green cterm=bold guifg=LightSalmon gui=bold
  highlight ywtxt_heading9 ctermfg=blue cterm=bold guifg=LightSkyBlue gui=bold
  highlight ywtxt_heading10 ctermfg=yellow cterm=bold guifg=LightGoldenrod gui=bold
else
  highlight ywtxt_heading1 ctermfg=blue cterm=bold guifg=Blue1 gui=bold
  highlight ywtxt_heading2 ctermfg=yellow cterm=bold guifg=DarkGoldenrod gui=bold
  highlight ywtxt_heading3 ctermfg=cyan cterm=bold guifg=Purple gui=bold
  highlight ywtxt_heading4 ctermfg=red cterm=bold guifg=red gui=bold
  highlight ywtxt_heading5 ctermfg=green cterm=bold guifg=ForestGreen gui=bold
  highlight ywtxt_heading6 ctermfg=magenta cterm=bold guifg=CadetBlue gui=bold
  highlight ywtxt_heading7 ctermfg=blue cterm=bold guifg=Orchid gui=bold
  highlight ywtxt_heading8 ctermfg=green cterm=bold guifg=RosyBrown gui=bold
  highlight ywtxt_heading9 ctermfg=blue cterm=bold guifg=Blue1 gui=bold
  highlight ywtxt_heading10 ctermfg=yellow cterm=bold guifg=DarkGoldenrod gui=bold
endif

let b:current_syntax = "ywtxt"

" vim: ts=2 sw=2 et
