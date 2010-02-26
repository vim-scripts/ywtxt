" mY oWn txt.
" Author: Yue Wu <ywupub@gmail.com>
" License: BSD

setlocal textwidth=72

setlocal fdm=expr
setlocal foldexpr=Ywtxt_FoldExpr(v:lnum)
setlocal foldtext=getline(v:foldstart)

nmap <silent> <buffer> <Tab> za
nmap <silent> <buffer> <Leader>t :call Ywtxt_TOC()<CR>
nmap <silent> <buffer> <Leader>i :call Ywtxt_CreateHeader(1)<CR>
nmap <silent> <buffer> <Leader>o :call Ywtxt_CreateHeader(0)<CR>
nmap <silent> <buffer> <Leader><s-o> :call Ywtxt_CreateHeader(-1)<CR>

" nmap <silent> <buffer> <Leader>o :call Yworg_createheader_dialog()<CR>
" map <silent> <buffer> <leader>< :call Yworg_reindent("l")<CR>
" map <silent> <buffer> <leader>> :call Yworg_reindent("r")<CR>
" nmap <silent> <buffer> <C-j> :call Yworg_createheader_dialog()<CR>
