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
    let bufwinnr = bufwinnr(b:ywtxt_bufnr)
    if bufwinnr
        execute bufwinnr . 'wincmd w'
        execute 'normal ' . l . 'Gzv'
    endif
endfunction "}}}

function Ywtxt_TOC() "{{{ Table of Contents
    let bufnr = bufnr("")
    let bufheight = 12
    let cur_cursor = line(".")
    let filelst = readfile(expand('%'))
    let fe = &fileencoding
    let enc = &encoding
    let m = 1
    let n = 1
    let s:Ywtxt_TOC = []
    for l in filelst
        if match(l, s:ywtxt_headerexpr) == 0
            if m <= cur_cursor
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
    let bufwnr = bufwinnr('_' . expand("%:r") . '_TOC_')
    if bufwnr == -1
        if toc_len < bufheight
            let bufheight = toc_len
        endif
        execute 'keepalt ' . bufheight . 'split _' .  expand("%:t") . '_TOC_'
        setlocal buftype=nofile
        setlocal bufhidden=hide
        setlocal noswapfile
        execute 'set fileencoding='. fe
        setlocal filetype=ywtxt
        let b:ywtxt_bufnr = bufnr
    elseif bufwnr != -1
        execute bufwnr . 'wincmd w'
    endif
    setlocal modifiable
    for l in range(toc_len)
        call append(line("$"), s:Ywtxt_TOC[l][0])
    endfor
    execute 'normal dd' . (n - 1) . 'Gzv'
    setlocal nomodifiable
    nmap <silent> <buffer> q :bwipeout<CR>
    nmap <silent> <buffer> <Space> :call Ywtxt_Jump()<CR>
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

" vim: foldmethod=marker:
