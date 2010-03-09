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

" User vars:
let s:ywtxt_biblioname = 'References'
if exists("g:ywtxt_biblioname")
    let s:ywtxt_biblioname = g:ywtxt_biblioname
    unlet g:ywtxt_biblioname
endif
if exists("g:ywtxt_tocwidth")
    let s:ywtxt_tocwidth = g:ywtxt_tocwidth
    unlet g:ywtxt_tocwidth
endif
let s:ywtxt_syntax_todo = ''
if exists("g:ywtxt_syntax_todo")
    let s:ywtxt_syntax_todo = g:ywtxt_syntax_todo
    unlet g:ywtxt_syntax_todo
endif
let s:ywtxt_syntax_note = ''
if exists("g:ywtxt_syntax_note")
    let s:ywtxt_syntax_note = g:ywtxt_syntax_note
    unlet g:ywtxt_syntax_note
endif

let s:ywtxt_refpat = '\^\[[^]]*\]'
let s:ywtxt_headingsymbol = '#.'
let s:ywtxt_heading1_expr_lst = '^\%(#\|\d\+\)\.\s'
let s:ywtxt_headingn_expr_lst = '^\s\{3,\}\%(\%(#\|\d\+\)\.\)\+\%(#\|\d\+\)\s'

let s:ywtxt_htmlpretagsl = ['<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>', '<pre style="word-wrap: break-word; white-space: pre-wrap; white-space: -moz-pre-wrap" >']

function Ywtxt_FoldExpr(l) "{{{ Folding rule.
    let line=getline(a:l)
    if (match(line, s:ywtxt_heading1_expr_lst) != -1)
        return '>1'
    elseif (match(line, s:ywtxt_headingn_expr_lst) != -1)
        let indent = strlen(matchstr(line, '^\s*'))
        if indent % 3 != 0
            continue
        endif
        let match_heading_indent = indent / 3
        let match_heading_num = len(split(matchstr(line, '^\s*\zs\%(\%(#\|\d\+\)\.\)\+\%(#\|\d\+\)\ze\s'), '\.'))
        if (match_heading_indent + 1) == match_heading_num
            return '>' . match_heading_num
        else
            return '='
        endif
    else
        return '='
    endif
endfunction "}}}

function Ywtxt_WinJump(n) "{{{ Mom win <-> toc win
    " a:n: == 2: wipeout the toc window
    let tocwp = match(bufname(""), '_.*_TOC_') + 1 " Detect if toc(1) or mom(0) window
    let toc = <SID>Ywtxt_GetHeadings()
    if tocwp
        let bufnr = bufnr(bufname(""))
        let bufwinnr = bufwinnr(b:ywtxt_toc_mom_bufnr)
        if bufwinnr
            let l = toc[0][line('.') - 1][2]
            execute bufwinnr . 'wincmd w'
            execute 'normal ' . l . 'Gzv'
        endif
        if a:n == 2
            execute 'bwipeout ' . bufnr
        endif
    else
        call <SID>Ywtxt_OpenTOC()
    endif
endfunction "}}}

function s:Ywtxt_GetHeadings() "{{{ Get headings
    if match(bufname(""), '_.*_TOC_') == -1 " For mom window
        let filelst = getbufline("", 1, '$')
        let bufnr = bufnr("")
        let bufname = expand("%:t:r")
        let cur_cursor = line(".")
    else
        let cur_cursor = line('.')
        let filelst = getbufline(b:ywtxt_toc_mom_bufnr, 1, '$')
    endif
    let momlnum = 0
    let toclst = []
    let n = 1
    let secmaxlev = 0
    for line in filelst
        let momlnum += 1
        let heading = matchstr(line, s:ywtxt_heading1_expr_lst)
        if heading != ''
            let match_heading_indent = 0
            let hlevel = 1
        elseif (match(line, s:ywtxt_headingn_expr_lst) != -1)
            let indent = strlen(matchstr(line, '^\s*'))
            if indent % 3 != 0
                continue
            endif
            let match_heading_indent = indent / 3
            let match_heading_num = len(split(matchstr(line, '^\s*\zs\%(\%(#\|\d\+\)\.\)\+\%(#\|\d\+\)\ze\s'), '\.'))
            if (match_heading_indent + 1) == match_heading_num
                let hlevel = match_heading_num
            endif
        else
            continue
        endif
        if hlevel
            " number generating
            if !exists("sec" . hlevel) || (secmaxlev < hlevel)
                execute 'let sec' . hlevel . '=1'
            else
                execute 'let sec' . hlevel . '+=1'
            endif
            let secmaxlev = hlevel
            if momlnum <= cur_cursor
                let n = len(toclst) + 1
            endif
            let secnum = ''
            if hlevel == 1
                let secnum .=sec1 . ". "
            else
                for li in range(1, hlevel)
                    if li != hlevel
                        execute 'let secnum .=sec' . li . ' . "."'
                    else
                        execute 'let secnum .=sec' . li . ' . " "'
                    endif
                endfor
            endif
            let tail = matchstr(line, '^\s*[#[:digit:].]\+\s\zs.*')
            call add(toclst, [heading, tail, momlnum, repeat(' ', (3 * (hlevel - 1))) . secnum])
            " real line: heading(0) + tail(1). momlnum(2): file_mom current line number in Mom window. secnum(3): section number.
        endif
    endfor
    return [toclst, n] " n: curren section
endfunction "}}}

function Ywtxt_OpenTOC() "{{{ Open and refresh toc.
    let toc = <SID>Ywtxt_GetHeadings()
    let tocwp = match(bufname(""), '_.*_TOC_') + 1 " Detect if toc(1) or mom(0) window
    if tocwp " For toc window
        let cur_cursor = line('.')
        let filelst = getbufline(b:ywtxt_toc_mom_bufnr, 1, '$')
    else " For mom window
        let filelst = getbufline("", 1, '$')
        let bufnr = bufnr("")
        let bufname = expand("%:t:r")
        let cur_cursor = toc[1]
    endif
    let toc_len = len(toc[0])
    if tocwp == 0 " For mom window
        let bufwnr = bufwinnr('_' . bufname . '_TOC_')
        if bufwnr == -1
            let tocwidth = (winwidth(bufwinnr(bufnr)) / 4)
            if exists("s:ywtxt_tocwidth")
                let tocwidth = s:ywtxt_tocwidth
            endif
            execute 'keepalt ' . tocwidth . 'vsplit _' .  bufname . '_TOC_'
            setlocal buftype=nofile
            setlocal bufhidden=hide
            setlocal noswapfile
            setlocal filetype=ywtxt
            let b:ywtxt_toc_mom_bufnr = bufnr
        elseif bufwnr != -1
            execute bufwnr . 'wincmd w'
        endif
    endif
    let toclns = []
    for l in range(toc_len)
        call add(toclns, toc[0][l][3] . toc[0][l][1])
    endfor
    setlocal modifiable
    %d
    call setline(1, toclns)
    execute 'normal ' . cur_cursor . 'Gzv'
    setlocal nomodifiable
endfunction "}}}

function Ywtxt_CreateHeading(l) "{{{ Create Heading.
    let fl = foldlevel(".")
    let ln = foldclosedend('.')
    if ln == -1
        let ln = line('.')
    endif
    if (fl + a:l) > 1
        let heading = repeat(' ', (3 * (foldlevel(".") + a:l - 1))) . repeat(s:ywtxt_headingsymbol, (foldlevel(".") + a:l - 1)) . '#'
    else
        let heading = s:ywtxt_headingsymbol
    endif
    execute ln . "put ='" . heading . " '"
    normal zv
    startinsert!
endfunction "}}}

function Ywtxt_toc_cmd(op,pos,...) "{{{ command on mom file in toc window.
    " a:op: operation name. a:pos: operation is in Mom(1) or toc(0) window?
    if match(bufname(""), '_.*_TOC_') == -1
        return
    endif
    let toc_save_cursor = getpos(".")
    call Ywtxt_WinJump(a:pos)
    let save_cursor = getpos(".")
    if a:op == 'undo' " undo
        silent! undo
    elseif a:op == 'redo' " redo
        silent! redo
    elseif a:op == 'save' " save buffer
        write
    elseif a:op == '2html' " Export to html.
        silent call <SID>Ywtxt_ToHtml()
        return
    elseif a:op == 'syncheading' " Sync with the heading number.
        let toc = <SID>Ywtxt_GetHeadings()
        for l in toc[0]
            call setline(l[2], l[3] . l[1])
        endfor
    elseif a:op == 'genrefs' " Generate Bibliography.
        call <SID>Ywtxt_GenBibliography()
    endif
    call setpos('.', save_cursor)
    wincmd p
    silent call Ywtxt_OpenTOC()
    call setpos('.', toc_save_cursor)
endfunction "}}}

function Ywtxt_ReIndent(d) "{{{ Reindent
    " a:d: direction
    let toc = <SID>Ywtxt_GetHeadings()
    let startline=line(".")
    let curln = startline + 1
    let prevlevel = foldlevel(startline - 1)
    let level = foldlevel('.')
    let endline = line('$')
    while (foldlevel(curln) > level) && (curln <= endline)
        let curln += 1
    endwhile
    let curln -= 1
    call Ywtxt_WinJump(1)
    let save_cursor = getpos(".")
    let n = 1
    for i in toc[0][startline - 1 : curln - 1]
        if a:d == 'l'
            if n == 1
                if level == 2
                    call setline(i[2], substitute(i[3] . i[1], '^\s*[#[:digit:].]*', '#.', ''))
                elseif level > 1
                    call setline(i[2], substitute(i[3] . i[1], '^\s*\zs\s\{3\}\%(#\|\d\+\)\.\ze', '', ''))
                endif
                let n += 1
            else
                call setline(i[2], substitute(i[3] . i[1], '^\s*\zs\s\{3\}\%(#\|\d\+\)\.\ze', '', ''))
            endif
        elseif a:d == 'r' && (level <= prevlevel)
            if n == 1
                if level == 1
                    call setline(i[2], substitute(i[3] . i[1], '^\%(#\|\d\+\)\.\ze\s', repeat(' ', 3 ) . '#.#', ''))
                else
                    call setline(i[2], substitute(i[3] . i[1], '^\s*\zs\ze\S', repeat(' ', 3 ) . '#.', ''))
                endif
                let n += 1
            else
                call setline(i[2], substitute(i[3] . i[1], '^\s*\zs\ze\S', repeat(' ', 3 ) . '#.', ''))
            endif
        endif
    endfor
    call setpos('.', save_cursor)
    call Ywtxt_OpenTOC()
endfunction "}}}

function s:Ywtxt_OpenBibFile(w) " {{{ Open bib file.
    let bibfile = matchstr(getline(searchpos('^\s*% bibfile = ', 'nw')[0]), '^\s*% bibfile = ''\zs[^'']*')
    let bufwnr = bufwinnr(expand(bibfile))
    if bufwnr == -1
        execute 'split ' . bibfile
    else
        execute bufwnr . 'wincmd w'
    endif
    call search('{' . a:w . '\>', 'w')
    normal zv
endfunction "}}}

function s:Ywtxt_GetBibEntry(...) " {{{ Show bib entry
    if exists("a:1")
        let ywbib_cur_bibentry = a:1
    else
        let ywbib_cur_bibentry = expand("<cword>")
    endif
    let bibfile = matchstr(getline(searchpos('^\s*% bibfile = ', 'nw')[0]), '^\s*% bibfile = ''\zs[^'']*')
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

function s:Ywtxt_GenBibliography() "{{{ Generate bibliography.
    let save_cursor = getpos(".")
    let refsi = searchpos('\%(' . s:ywtxt_heading1_expr_lst . '\|' . s:ywtxt_headingn_expr_lst . '\)' . s:ywtxt_biblioname, 'nw')[0]
    let refei = searchpos('^\s*% bibfile = ', 'nw')[0]
    if (refsi == 0) || (refei == 0) || (refei < (refsi + 1))
        echohl ErrorMsg
        echo "References section not found, see the document to make .bib support work."
        echohl None
        return
    endif
    call <SID>Ywtxt_GetRefLst()
    let reflns = []
    for l in range(1, len(s:ywtxt_refdic))
        call add(reflns, '['. l . '] ' . s:ywtxt_refdic[l][1])
    endfor
    let reflns = [''] + reflns + ['']
    setlocal nofoldenable
    execute (refsi + 1) . ',' . (refei - 1) . 'delete'
    setlocal foldenable
    call append(refsi, reflns)
    call setpos('.', save_cursor)
endfunction "}}}

function s:Ywtxt_GetRefLst() "{{{ Get bibs
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
        let ent = <SID>Ywtxt_GetBibEntry(e)
        if ent !~ '^\s*$'
            let s:ywtxt_refdic[n] = [e, ent]
            " n: number. e(0): keyword, ent(1): generated reference show.
            " call add(reflst, '[' . n . '] ' . ent)
            let n += 1
        endif
    endfor
    call setpos('.', save_cursor)
endfunction "}}}

function Ywtxt_keymaps() "{{{ key maps.
    nmap <silent> <buffer> <Tab> :call Ywtxt_Tab('t')<CR>
    nmap <silent> <buffer> <Leader>t :call Ywtxt_OpenTOC()<CR>
    if match(bufname(""), '_.*_TOC_') == -1 " For mom window
        nmap <silent> <buffer> <Leader>i :call Ywtxt_CreateHeading(1)<CR>
        nmap <silent> <buffer> <Leader>o :call Ywtxt_CreateHeading(0)<CR>
        nmap <silent> <buffer> <Leader><s-o> :call Ywtxt_CreateHeading(-1)<CR>
        nmap <silent> <buffer> <Leader>q :execute 'silent! bwipeout ' . bufnr('_' . expand("%:t:r") . '_TOC_')<CR>
        nmap <silent> <buffer> <Leader><tab> :execute 'silent! ' . bufwinnr('_' . expand("%:t:r") . '_TOC_') . 'wincmd w'<CR>
        nmap <silent> <buffer> <CR> :call Ywtxt_Tab('e')<CR>
        imap <buffer> _ _{}<Left>
        imap <buffer> ^{ ^{}<Left>
        imap <buffer> ^[ ^[]<Left>
    else " For toc window
        nmap <silent> <buffer> q :bwipeout<CR>
        nmap <silent> <buffer> r :call Ywtxt_OpenTOC()<CR>
        nmap <silent> <buffer> <Space> zz:call Ywtxt_WinJump(1) <bar> wincmd p<CR>
        nmap <silent> <buffer> <Enter> :call Ywtxt_WinJump(1)<CR>
        nmap <silent> <buffer> <s-x> zx:call Ywtxt_WinJump(1)<CR>zx:wincmd p<CR>
        nmap <silent> <buffer> x :call Ywtxt_WinJump(2)<CR>
        nmap <silent> <buffer> <leader>< :call Ywtxt_ReIndent('l')<CR>
        nmap <silent> <buffer> <leader>> :call Ywtxt_ReIndent('r')<CR>
        nmap <silent> <buffer> u :call Ywtxt_toc_cmd('undo', 0)<CR>
        nmap <silent> <buffer> <c-r> :call Ywtxt_toc_cmd('redo', 0)<CR>
        nmap <silent> <buffer> w :call Ywtxt_toc_cmd('save', 0)<CR>
        nmap <silent> <buffer> <Leader><tab> :execute 'silent! ' . bufwinnr(b:ywtxt_toc_mom_bufnr) . 'wincmd w'<CR>
        nmap <silent> <buffer> <s-s> :call Ywtxt_toc_cmd('syncheading', 0)<CR>
        nmap <silent> <buffer> <s-b> :call Ywtxt_toc_cmd('genrefs', 0)<CR>
        nmap <silent> <buffer> <s-e> :call Ywtxt_toc_cmd('2html', 2)<CR>
    endif
endfunction "}}}

function Ywtxt_Tab(k) "{{{ Function for <enter>
    let refsi = searchpos(s:ywtxt_biblioname, 'nw')[0]
    let refei = searchpos('^\s*% bibfile = ', 'nw')[0]
    let line = getline('.')
    let lnum = line('.')
    if (refsi > 0) && (lnum > refsi) && (lnum < refei)
        let num = matchstr(line, '^\[\zs\d\+\ze\]')
        if num != ''
            if a:k == 't'
                call search(s:ywtxt_refdic[num][0], 'w')
                normal zv
            elseif a:k == 'e'
                call <SID>Ywtxt_OpenBibFile(s:ywtxt_refdic[num][0])
            endif
            return
        endif
    else
        let kwd = expand('<cword>')
        if match(line, '\^\[[^]]*' . kwd . '[^]]*\]') != -1
            if a:k == 't'
                echohl MoreMsg
                echo <SID>Ywtxt_GetBibEntry(kwd)
                echohl None
            elseif a:k == 'e'
                call <SID>Ywtxt_OpenBibFile(kwd)
            endif
            return
        endif
    endif
    if a:k == 't'
        silent! normal za
    elseif a:k == 'e'
        normal j
    endif
endfunction "}}}

function s:Ywtxt_ToHtml(...) "{{{ ywtxt to html
    call <SID>Ywtxt_GetRefLst()
    normal zR
    if exists("a:1")
        let ls = a:1
        let le = a:2
    else
        let ls = 1
        let le = line('$')
    endif
    execute ls . ',' . le . 'TOhtml'
    %s/^\%(<[^>]*>\)*\(\%(#\|\d\+\)\.\s[^<]*\)\ze</<h1>\1<\/h1>/e " heading
    for i in range(1, 3)
        execute '%s/^\%(<[^>]*>\)*\(\%(\%(#\|\d\+\)\.\)\{' . i . '\}\%(#\|\d\+\)\s[^<]*\)\ze</<h' . (i + 1) . '>\1<\/h' . (i + 1) . '>/e'
    endfor
    %s/^\%(<[^>]*>\)*\(\%(\%(#\|\d\+\)\.\)\{4,\}\%(#\|\d\+\)\s[^<]*\)\ze</<h4>\1<\/h4>/e
    g/<b>\s*%[^<]*<\/b>/d " Delete the comment line
    %s/<b>\zs\*\([^<]*\)\*\ze</\1/ge " boldface
    %s/<i>\zs\/\([^<]*\)\/\ze</\1/ge " italic
    %s/<u>\zs_\([^<]*\)_\ze</\1/ge " underlined
    if len(s:ywtxt_refdic) != 0 "  replace the ref keyword with the citing number.
        for i in range(1, len(s:ywtxt_refdic))
            execute '%s/\^\[[^]]*\zs' . s:ywtxt_refdic[i][0] . '\ze[^]]*]/' . i . '/g'
        endfor
    endif
    %s/\^{\([^}]\+\)}/<sup>\1<\/sup>/ge " superscript html
    %s/_{\([^}]\+\)}/<sub>\1<\/sub>/ge " subscript html
    %s/\^\(\[[^]]\+\]\|{[^}]\+}\)/<sup>\1<\/sup>/ge " superscript citing number html
    %s/\[\s*\f*\.\%(jpg\|png\|bmp\|gif\)\s*\]/\='<img src=' . substitute(submatch(0)[1 : -2], '\s', '%20', 'g') . '>'/gei " pictures
endfunction "}}}
" command -bar -range=% YwtxtTOhtml call Ywtxt_ToHtml(<line1>,<line2>)

function Ywtxt_Indent() "{{{ Indent func.
    let curln = getline('.')
    if match(curln, '^\%(#\|\d\+\)\.\s\+') == 0
        return 0
    elseif match(curln, '^\s*\%(\%(#\|\d\+\)\.\)\+\%(#\|\d\+\)\s\+') == 0
        return (3 * (foldlevel('.') - 1))
    else
        return (3 * foldlevel('.'))
    endif
endfunction "}}}

function Ywtxt_old2new() "{{{ TODO Old to new, will delete soon!
    for l in range(1, line('$'))
        let line = getline(l)
        if match(line, '^\%(\%(#\|\d\+\)\.\)\+\%\(#\|\d\+\)\ze\.\s') == 0
            let head = matchstr(line, '^\%(\%(#\|\d\+\)\.\)\+\%\(#\|\d\+\)\ze\.\s')
            let tail = matchstr(line, '^[#[:digit:].]\+\zs\s.*')
            let level = len(split(head, '\.'))
            call setline(l, repeat(' ', 3 * (level - 1)) . head . tail)
        endif
    endfor
endfunction

" vim: foldmethod=marker:
