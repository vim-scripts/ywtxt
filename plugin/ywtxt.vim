" mY oWn txt.
" Author: Yue Wu <ywupub@gmail.com>
" License: BSD

if exists("s:loaded_ywtxt")
    finish
endif
let s:loaded_ywtxt = 1
scriptencoding utf-8

setlocal comments=":%"

let s:ywtxt_path = expand("<sfile>:p:h")

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

function Ywtxt_Jump(n) "{{{ Jump to mom buf
    let bufnr = bufnr(bufname(""))
    if a:n
        let l = s:ywtxt_TOC[line('.') - 1][2]
    else
        let l = b:ywtxt_toc_mom_bufline
    endif
    let bufwinnr = bufwinnr(b:ywtxt_toc_mom_bufnr)
    if bufwinnr
        execute bufwinnr . 'wincmd w'
        execute 'normal ' . l . 'Gzv'
    endif
    if a:n == 2
        execute 'bwipeout ' . bufnr
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
        let maxline = line("$")
        let bufname = expand("%:t:r")
        let bufheight = 12
        let cur_cursor = line(".")
        let filelst = getbufline("", 1, line('$'))
    elseif a:n == 0
        let filelst = getbufline(b:ywtxt_toc_mom_bufnr, 1, b:ywtxt_toc_mom_maxline)
        let cur_cursor = s:ywtxt_TOC[line(".") - 1][2]
    else
        return
    endif
    let rlinenum = 1
    let s:ywtxt_TOC = []
    let n = 1
    for line in filelst
        let header = matchstr(line, s:ywtxt_headerexpr)
        let hdlen = strlen(header)
        let hlen = (hdlen / 2)
        if hlen
            " number generating
            if !exists("sec" . hlen) || (secmaxlev < hlen)
                execute 'let sec' . hlen . '=1'
            else
                execute 'let sec' . hlen . '+=1'
            endif
            let secmaxlev = hlen
            if rlinenum <= cur_cursor
                let n = len(s:ywtxt_TOC) + 1
            endif
            let secnum = ''
            for li in range(1, hlen)
                execute 'let secnum .=sec' . li . ' . "."'
            endfor
            let tail = strpart(line, hdlen)
            call add(s:ywtxt_TOC, [header, tail, rlinenum, secnum])
            " line: header(0) + tail(1). rlinenum(2): file_mom real line num. secnum: sec num(3)
        endif
        let rlinenum += 1
    endfor
    let toc_len = len(s:ywtxt_TOC)
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
            let b:ywtxt_toc_mom_maxline = maxline
            let b:ywtxt_toc_mom_bufnr = bufnr
        elseif bufwnr != -1
            execute bufwnr . 'wincmd w'
        endif
        let b:ywtxt_toc_mom_bufline = cur_cursor
    endif
    let toc = []
    for l in range(toc_len)
        call add(toc, s:ywtxt_TOC[l][3] . s:ywtxt_TOC[l][1])
    endfor
    setlocal modifiable
    %d
    call setline(1, toc)
    execute 'normal ' . n . 'Gzv'
    setlocal nomodifiable
endfunction "}}}

function Ywtxt_CreateHeader(l) "{{{ Create Header.
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

function Ywtxt_toc_cmd(op,pos,...) "{{{ command on mom file in toc window.
    if match(bufname(""), '_.*_TOC_') == -1
        return
    endif
    let toc_save_cursor = getpos(".")
    call Ywtxt_Jump(a:pos)
    let save_cursor = getpos(".")
    if a:op == 'sync' " Sync with the header number.
        for l in s:ywtxt_TOC
            call setline(l[2], l[3] . l[1])
        endfor
    elseif a:op == 'reindent' " Reindent the level of header.
        let startline=line(".")
        let currenlinelevel = foldlevel(".")
        let endline = searchpos('^\(\d\+\|#\)\.\{1,' . currenlinelevel . '\}\s.*', 'nW')[0] - 1
        if endline == -1
            let endline = line("$")
        elseif endline == startline
            return
        endif
        if a:1 == 'l' && ( match(getline("."), '^\(\d\+\|#\)\.\s.*') != 0 )
            execute startline.','.endline.'s/^\%(\d\+\|#\)\.\([[:digit:]#.]\+\.\)\ze\s/\1/e'
        elseif a:1 == 'r'
            execute startline.','.endline.'s/^\(\%(\d\+\|#\)[[:digit:]#.]*\.\)\ze\s/#.\1/e'
        endif
    elseif a:op == 'undo' " undo
        silent! undo
    elseif a:op == 'redo' " redo
        silent! redo
    elseif a:op == 'save' " save buffer
        write
    endif
    call setpos('.', save_cursor)
    wincmd p
    call <SID>Ywtxt_TOC(0)
    call setpos('.', toc_save_cursor)
endfunction "}}}

" {{{ bib support
if file_readable(s:ywtxt_path . '/ywbib.vim')
    function Ywtxt_FindBibEntry() " {{{ Find bib entry
        " let g:ywbib_cur_bibentry = matchstr(getline("."), '\[\zs[^],]*\ze\]')
        let g:ywbib_cur_bibentry = expand("<cword>")
        let bibfile = matchstr(getline(searchpos('^% bibfile = ', 'nw')[0]), '^% bibfile = ''\zs[^'']*')
        let bufwnr = bufwinnr(expand(bibfile))
        if bufwnr == -1
            execute 'split ' . bibfile
        else
            execute bufwnr . 'wincmd w'
        endif
        call search('{' . g:ywbib_cur_bibentry . '\>', 'w')
        set foldmethod=expr
        setlocal foldtext=''
        setlocal foldexpr=Ywbib_FoldEntryOnly(v:lnum)
        normal zv
    endfunction "}}}
endif "}}}

function Ywtxt_keymaps() "{{{ key maps.
    nmap <silent> <buffer> <Tab> za
    if match(bufname(""), '_.*_TOC_') == -1
        nmap <silent> <buffer> <Leader>t :call Ywtxt_OpenTOC(1)<CR>
        nmap <silent> <buffer> <Leader>i :call Ywtxt_CreateHeader(1)<CR>
        nmap <silent> <buffer> <Leader>o :call Ywtxt_CreateHeader(0)<CR>
        nmap <silent> <buffer> <Leader><s-o> :call Ywtxt_CreateHeader(-1)<CR>
        nmap <silent> <buffer> <Leader>q :execute 'silent! bwipeout ' . bufnr('_' . expand("%:t:r") . '_TOC_')<CR>
        nmap <silent> <buffer> <Leader><tab> :execute 'silent! ' . bufwinnr('_' . expand("%:t:r") . '_TOC_') . 'wincmd w'<CR>
    else
        nmap <silent> <buffer> q :bwipeout<CR>
        nmap <silent> <buffer> r :call Ywtxt_OpenTOC(0)<CR>
        nmap <silent> <buffer> <Space> :call Ywtxt_Jump(1)<CR>
        nmap <silent> <buffer> <Enter> :call Ywtxt_Jump(1)<CR>
        nmap <silent> <buffer> x :call Ywtxt_Jump(2)<CR>
        nmap <silent> <buffer> <leader>< :call Ywtxt_toc_cmd('reindent', 1, 'l')<CR>
        nmap <silent> <buffer> <leader>> :call Ywtxt_toc_cmd('reindent', 1, 'r')<CR>
        nmap <silent> <buffer> <s-s> :call Ywtxt_toc_cmd('sync', 0)<CR>
        nmap <silent> <buffer> u :call Ywtxt_toc_cmd('undo', 0)<CR>
        nmap <silent> <buffer> <c-r> :call Ywtxt_toc_cmd('redo', 0)<CR>
        nmap <silent> <buffer> w :call Ywtxt_toc_cmd('save', 0)<CR>
        nmap <silent> <buffer> <Leader><tab> :execute 'silent! ' . bufwinnr(b:ywtxt_toc_mom_bufnr) . 'wincmd w'<CR>
    endif
endfunction "}}}

" vim: foldmethod=marker:
