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

let s:ywtxt_refpat = '\^\[[^]]*\]'
let s:ywtxt_headersymbol = '#.'
let s:ywtxt_headerexpr = '^\(\d\+\|#\)[[:digit:]#.]*\.\ze\s'
let s:ywtxt_biblioname = 'Bibliography'
if exists("g:ywtxt_biblioname")
    let s:ywtxt_biblioname = g:ywtxt_biblioname
    unlet g:ywtxt_biblioname
endif

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
        let bufname = expand("%:t:r")
        " let bufheight = 12
        let cur_cursor = line(".")
        let filelst = getbufline("", 1, '$')
    elseif a:n == 0
        let filelst = getbufline(b:ywtxt_toc_mom_bufnr, 1, '$')
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
            " if toc_len < bufheight
            "     let bufheight = toc_len
            " endif
            " execute 'keepalt ' . bufheight . 'split _' .  bufname . '_TOC_'
            execute 'keepalt ' . (winwidth(bufwinnr(bufnr)) / 4)  . 'vsplit _' .  bufname . '_TOC_'
            setlocal buftype=nofile
            setlocal bufhidden=hide
            setlocal noswapfile
            setlocal filetype=ywtxt
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
    let ln = foldclosedend('.')
    if ln == -1
        let ln = line('.')
    endif
    if (fl + a:l) > 0
        let header = repeat(s:ywtxt_headersymbol, (foldlevel(".") + a:l))
    else
        let header = s:ywtxt_headersymbol
    endif
    execute ln . "put ='" . header . " '"
    normal zv
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

function Ywtxt_OpenBibFile(w) " {{{ Open bib file.
    let bibfile = matchstr(getline(searchpos('^% bibfile = ', 'nw')[0]), '^% bibfile = ''\zs[^'']*')
    let bufwnr = bufwinnr(expand(bibfile))
    if bufwnr == -1
        execute 'split ' . bibfile
    else
        execute bufwnr . 'wincmd w'
    endif
    call search('{' . a:w . '\>', 'w')
    normal zv
endfunction "}}}

function Ywtxt_GetBibEntry(...) " {{{ Show bib entry
    if exists("a:1")
        let ywbib_cur_bibentry = a:1
    else
        let ywbib_cur_bibentry = expand("<cword>")
    endif
    let bibfile = matchstr(getline(searchpos('^% bibfile = ', 'nw')[0]), '^% bibfile = ''\zs[^'']*')
    if !filereadable(bibfile)
        if  !exists("a:1")
            echo 'No bib file found'
        endif
        return
    endif
    let bufnr = bufnr(expand(bibfile))
    if bufnr == -1
        let bibfilelist = readfile(expand(bibfile))
    else
        let bibfilelist = getbufline(bufnr, 1, '$')
    endif
    let entrysi = match(bibfilelist, '{' . ywbib_cur_bibentry . '\>')
    if entrysi == -1
        if !exists("a:1")
            echo 'No bib found'
        endif
        return
    endif
    let entryei = match(bibfilelist, '^\s*}$', entrysi)
    let entryitems = join(bibfilelist[entrysi + 1 : entryei - 1], "\n")
    let entryitemslst = split(entryitems, '[^\\]},\zs\s*')
    let bibentriesdic = {}
    for e in entryitemslst
        let key = matchstr(e, '\s*\zs[^=[:blank:]]*\ze\s*=\s*{')
        if key =~ '^\s*$'
            continue
        endif
        let value = matchstr(e, '=\s*{\s*\zs.*\ze\s*},$')
        let bibentriesdic[key] = value
    endfor
    if !exists("a:1") && has_key(bibentriesdic, 'url')
        echo "Hit any key other than <Enter> or <space> to open file.\n"
        let key = getchar()
        if (key != 13) || (key != 32)
            " 13: enter, 32: space
            if exists("*Ywrun_run")
                if match(bibfile, '\(/\|\d:\)') == 0
                    silent! call Ywrun_run(expand(bibentriesdic['url']))
                else
                    silent! call Ywrun_run(matchstr(bibfile, '.*/\ze.*$') . expand(bibentriesdic['url']))
                endif
            endif
        endif
    endif
    let entryshow = ""
    for entry in ['title', 'author', 'journal', 'year', 'volume', 'number', 'pages', 'url', 'abstract', 'contents', 'note']
        if has_key(bibentriesdic, entry)
            if entry =~ '\(title\|author\|journal\|year\|volume\|number\|pages\)'
                if entry == '\(journal\|year\)'
                    let entryshow .= bibentriesdic[entry] . ', '
                elseif entry == 'volume'
                    let entryshow .= bibentriesdic[entry]
                elseif entry == 'number'
                    let entryshow .= '(' . bibentriesdic[entry] . ') :'
                elseif entry == 'author'
                    let temp_entryshow = substitute(bibentriesdic[entry], '\s*and\s*', ', ', 'g')
                    let temp_entryshowlst = split(temp_entryshow, ', ')
                    if len(temp_entryshowlst) < 4
                        let entryshow .= temp_entryshow . '. '
                    else
                        if match(temp_entryshowlst[0], '\a') != -1
                            let etc = ' et. al'
                        else
                            let etc = '等'
                        endif
                        let entryshow .= join(temp_entryshowlst[0 : 2], ', ') . etc . '. '
                    endif
                else
                    let entryshow .= bibentriesdic[entry] . '. '
                endif
                " else
                "     echo "\n"
                "     for entrylst in split(bibentriesdic[entry] . '. ', "\n")
                "         echo entrylst
                "     endfor
            endif
        endif
    endfor
    if exists("a:1")
        return entryshow
    else
        echohl ErrorMsg
        echo entryshow
        echohl None
        " call append('$', [entry . ': ' . bibentriesdic[entry], ""])
    endif
endfunction "}}}

function Ywtxt_GenBibliography() "{{{ Generate bibliography.
    let save_cursor = getpos(".")
    let biblines = []
    let biblst=[]
    execute 'g/' . s:ywtxt_refpat . "/call add(biblines, getline('.'))"
    for line in biblines
        for bibs in filter(split(line, '\(\ze\^\[\|\]\zs\)'), "v:val =~ '\\^\\[[^]]*\\]'")
            for bib in split(substitute(bibs[2:-2], '\s\+', '', 'g'), ',')
                if index(biblst, bib) == -1
                    call add(biblst, bib)
                endif
            endfor
        endfor
    endfor
    let s:ywtxt_refdic = {}
    let n = 1
    for e in biblst
        let ent = Ywtxt_GetBibEntry(e)
        if ent !~ '^\s*$'
            let s:ywtxt_refdic[n] = [e, ent]
            " e: keyword, ent: generated reference show.
            " call add(reflst, '[' . n . '] ' . ent)
            let n += 1
        endif
    endfor
    let refsi = searchpos(s:ywtxt_biblioname, 'w')[0]
    let refei = searchpos('% bibfile = ', 'w')[0]
    let reflns = []
    for l in range(1, len(s:ywtxt_refdic))
        call add(reflns, '['. l . '] ' . s:ywtxt_refdic[l][1])
    endfor
    let reflns = [''] + reflns + ['']
    if refsi == 0
        let refsi = '$'
        call insert(reflns, s:ywtxt_biblioname)
    elseif refei > (refsi + 1)
        setlocal nofoldenable
        execute (refsi + 1) . ',' . (refei - 1) . 'delete'
        setlocal foldenable
    endif
    call append(refsi, reflns)
    call setpos('.', save_cursor)
endfunction "}}}

function Ywtxt_keymaps() "{{{ key maps.
    nmap <silent> <buffer> <Tab> :call Ywtxt_Tab('t')<CR>
    if match(bufname(""), '_.*_TOC_') == -1 " For mom window
        nmap <silent> <buffer> <Leader>t :call Ywtxt_OpenTOC(1)<CR>
        nmap <silent> <buffer> <Leader>i :call Ywtxt_CreateHeader(1)<CR>
        nmap <silent> <buffer> <Leader>o :call Ywtxt_CreateHeader(0)<CR>
        nmap <silent> <buffer> <Leader><s-o> :call Ywtxt_CreateHeader(-1)<CR>
        nmap <silent> <buffer> <Leader>q :execute 'silent! bwipeout ' . bufnr('_' . expand("%:t:r") . '_TOC_')<CR>
        nmap <silent> <buffer> <Leader><tab> :execute 'silent! ' . bufwinnr('_' . expand("%:t:r") . '_TOC_') . 'wincmd w'<CR>
        nmap <silent> <buffer> <CR> :call Ywtxt_Tab('e')<CR>
    else " For toc window
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

function Ywtxt_Tab(k) "{{{ Function for <enter>
    let refsi = searchpos(s:ywtxt_biblioname, 'nw')[0]
    let refei = searchpos('% bibfile = ', 'nw')[0]
    let line = getline('.')
    let lnum = line('.')
    if refsi > 0 && lnum > refsi && lnum < refei
        let num = matchstr(line, '^\[\zs\d\+\ze\]')
        if num != ''
            if a:k == 't'
                call search(s:ywtxt_refdic[num][0], 'w')
                normal zv
            elseif a:k == 'e'
                call Ywtxt_OpenBibFile(s:ywtxt_refdic[num][0])
            endif
            return
        endif
    else
        let kwd = expand('<cword>')
        if match(line, '\^\[[^]]*' . kwd . '[^]]*\]') != -1
            if a:k == 't'
                echohl MoreMsg
                echo Ywtxt_GetBibEntry(kwd)
                echohl None
            elseif a:k == 'e'
                call Ywtxt_OpenBibFile(kwd)
            endif
            return
        endif
    endif
    if a:k == 't'
        normal za
    elseif a:k == 'e'
        normal j
    endif
endfunction "}}}

function s:Ywtxt_ToHtml() "{{{ TODO ywtxt to html
    let file = input("Which file?: ", "", "file")
    if filereadable(file)
        return
    endif
    !% > file
    execute 'edit ' . file
    %s/^\%(#\.\|\d\+\.\)\s\(.*$\)/<h1>\1\<h1>/
    %s/^\%(#\.\|\d\+\.\)\{1\}\s\(.*$\)/<h2>\1\<h2>/
    %s/\s\zs\*\(\S\+\)\*\ze\s/<strong>\1\<strong2>/
    %s/\s\zs\(\S\+\.\(jpg\|png\|bmp\)\)/<img src="\1">/
endfunction "}}}

" vim: foldmethod=marker:
