" mY oWn txt.
" Author: Yue Wu <ywupub@gmail.com>
" License: BSD

setlocal textwidth=72

setlocal fdm=expr
setlocal foldexpr=Ywtxt_FoldExpr(v:lnum)
setlocal foldtext=getline(v:foldstart)

call Ywtxt_keymaps()

" nmap <silent> <buffer> <Leader>o :call Yworg_createheader_dialog()<CR>
" map <silent> <buffer> <leader>< :call Yworg_reindent("l")<CR>
" map <silent> <buffer> <leader>> :call Yworg_reindent("r")<CR>
" nmap <silent> <buffer> <C-j> :call Yworg_createheader_dialog()<CR>
