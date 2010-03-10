" mY oWn txt.
" Author: Yue Wu <ywupub@gmail.com>
" License: BSD

setlocal textwidth=72

setlocal fdm=expr
setlocal foldexpr=Ywtxt_FoldExpr(v:lnum)
setlocal foldtext=getline(v:foldstart)

if match(bufname(""), '_.*_TOC_') == 0 " For toc window
    setlocal cursorline
else " For mom window
endif

call Ywtxt_keymaps()
