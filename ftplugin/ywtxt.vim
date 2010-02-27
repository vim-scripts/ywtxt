" mY oWn txt.
" Author: Yue Wu <ywupub@gmail.com>
" License: BSD

setlocal textwidth=72

setlocal fdm=expr
setlocal foldexpr=Ywtxt_FoldExpr(v:lnum)
setlocal foldtext=getline(v:foldstart)

call Ywtxt_keymaps()
