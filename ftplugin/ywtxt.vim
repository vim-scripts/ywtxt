" mY oWn txt.
" Author: Yue Wu <ywupub@gmail.com>
" License: BSD

scriptencoding utf-8

setlocal fdm=expr
setlocal foldexpr=Ywtxt_FoldExpr(v:lnum)
setlocal foldtext=getline(v:foldstart)

if match(bufname(""), '_.*_TOC_') == 0 " For toc window
    setlocal cursorline
else " For mom window
endif

setlocal comments=":%"

call Ywtxt_FindSnipft()
call Ywtxt_keymaps()
