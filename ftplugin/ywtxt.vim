" mY oWn txt.
" Author: Yue Wu <ywupub@gmail.com>
" License: BSD

scriptencoding utf-8

if match(bufname(""), '_.*_TOC_') == 0 " For toc window
    setlocal fdm=expr
    setlocal foldexpr=Ywtxt_toc_FoldExpr(v:lnum)
    setlocal cursorline
else " For mom window
    setlocal fdm=syntax
endif
setlocal foldtext=getline(v:foldstart)

setlocal comments=:%
setlocal isf-=[
setlocal formatoptions+=ro

call Ywtxt_FindSnipft()
call Ywtxt_keymaps()
