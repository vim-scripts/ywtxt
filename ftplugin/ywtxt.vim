" mY oWn txt.
" Author: Yue Wu <ywupub@gmail.com>
" License: BSD

setlocal textwidth=72

setlocal fdm=expr
setlocal foldexpr=Ywtxt_FoldExpr(v:lnum)
setlocal foldtext=getline(v:foldstart)
setlocal indentexpr=Ywtxt_Indent()
setlocal indentkeys+=#,.,1,2,3,4,5,6,7,8,9

if match(bufname(""), '_.*_TOC_') == 0 " For toc window
    setlocal cursorline
endif

call Ywtxt_keymaps()
