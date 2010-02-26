" mY oWn txt.
" Author: Yue Wu <ywupub@gmail.com>
" License: BSD

if exists("s:loaded_ywtxt")
    finish
endif
let s:loaded_ywtxt = 1
scriptencoding utf-8

setlocal comments=":%"

let s:ywtxt_headersymbol = '#.'
let s:ywtxt_headerexpr = '^\(\d\+\|#\)[[:digit:]#.]*\.\ze\s'

function Ywtxt_FoldExpr(l) "{{{ Folding rule.
    let line=getline(a:l)
    if match(line, s:ywtxt_headerexpr) != -1
    let match_header = matchstr(line, s:ywtxt_headerexpr)
        return '>' . (strlen(match_header) / 2)
    else
        return '='
    endif
endfunction "}}}

function Ywtxt_Jump() "{{{ Jump to txt
    let l = s:Ywtxt_TOC[line('.') - 1][1]
    let bufwinnr = bufwinnr(b:ywtxt_toc_mom_bufnr)
    if bufwinnr
        execute bufwinnr . 'wincmd w'
        execute 'normal ' . l . 'Gzv'
    endif
endfunction "}}}

function Ywtxt_OpenTOC(n) "{{{ Open toc window
    " a:n == 1: open toc window, a:n == 0: just refresh toc.
    call <SID>Ywtxt_TOC(a:n)
endfunction "}}}

function s:Ywtxt_TOC(n) "{{{ Generate toc.
    " a:n == 1: open toc window, a:n == 0: just refresh toc.
    if a:n == 1
        let bufnr = bufnr("")
        let bufname = expand("%:t:r")
        let bufheight = 12
        let cur_cursor = line(".")
        let filelst = readfile(expand('%'))
    elseif a:n == 0
        let filelst = readfile(bufname(b:ywtxt_toc_mom_bufnr))
        let cur_cursor = s:Ywtxt_TOC[line(".") - 1][1]
    else
        return
    endif
    let fe = &fileencoding
    let enc = &encoding
    let m = 1
    let n = 1
    let s:Ywtxt_TOC = []
    for l in filelst
        if match(l, s:ywtxt_headerexpr) == 0
            if m < cur_cursor
                let n += 1
            endif
            call add(s:Ywtxt_TOC, [l, m])
        endif
        let m += 1
    endfor
    let toc_len = len(s:Ywtxt_TOC)
    if ( fe != enc ) && has("iconv")
        for i in range(toc_len)
            let s:Ywtxt_TOC[i][0] = iconv(s:Ywtxt_TOC[i][0], fe, enc)
        endfor
    endif
    if a:n == 1
        let bufwnr = bufwinnr('_' . bufname . '_TOC_')
        if bufwnr == -1
            if toc_len < bufheight
                let bufheight = toc_len
            endif
            execute 'keepalt ' . bufheight . 'split _' .  bufname . '_TOC_'
            setlocal buftype=nofile
            setlocal bufhidden=hide
            setlocal noswapfile
            setlocal filetype=ywtxt
            execute 'set fileencoding='. fe
            let b:ywtxt_toc_mom_bufnr = bufnr
        elseif bufwnr != -1
            execute bufwnr . 'wincmd w'
        endif
    endif
    let toc = []
    for l in range(toc_len)
        call add(toc, s:Ywtxt_TOC[l][0])
    endfor
    setlocal modifiable
    %d
    call setline(1, toc)
    execute 'normal ' . n . 'Gzv'
    setlocal nomodifiable
endfunction "}}}

function Ywtxt_CreateHeader(l) "{{{
    let fl = foldlevel(".")
    if (fl + a:l) > 0
        let header = repeat(s:ywtxt_headersymbol, (foldlevel(".") + a:l))
    else
        let header = s:ywtxt_headersymbol
    endif
    put =header . ' '
    startinsert!
endfunction
"}}}

function Ywtxt_keymaps() "{{{ key maps for normal window
    nmap <silent> <buffer> <Tab> za
    if match(bufname(""), '_.*_TOC_') == -1
        nmap <silent> <buffer> <Leader>t :call Ywtxt_OpenTOC(1)<CR>
        nmap <silent> <buffer> <Leader>i :call Ywtxt_CreateHeader(1)<CR>
        nmap <silent> <buffer> <Leader>o :call Ywtxt_CreateHeader(0)<CR>
        nmap <silent> <buffer> <Leader><s-o> :call Ywtxt_CreateHeader(-1)<CR>
        nmap <silent> <buffer> <Leader>q :execute 'silent! bwipeout ' . bufnr('_' . expand("%:t:r") . '_TOC_')<CR>
    else
        nmap <silent> <buffer> q :bwipeout<CR>
        nmap <silent> <buffer> r :call Ywtxt_OpenTOC(0)<CR>
        nmap <silent> <buffer> <Space> :call Ywtxt_Jump()<CR>
    endif
endfunction "}}}

" vim: foldmethod=marker:
