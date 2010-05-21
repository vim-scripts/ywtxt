" mY oWn txt.
" Author: Yue Wu <ywupub@gmail.com>
" License: BSD

if exists("s:loaded_ywtxt")
    finish
endif
let s:loaded_ywtxt = 1
scriptencoding utf-8

let s:ywtxt_path = expand("<sfile>:p:h")

" User vars:
if exists("g:ywtxt_tocwidth")
    let s:ywtxt_tocwidth = g:ywtxt_tocwidth
    unlet g:ywtxt_tocwidth
endif
if exists("g:ywtxt_HeadingsPat")
    let s:ywtxt_HeadingsPat = g:ywtxt_HeadingsPat
    unlet g:ywtxt_HeadingsPat
endif
if exists("g:ywtxt_autonumber")
    let s:ywtxt_autonumber = g:ywtxt_autonumber
else
    let s:ywtxt_autonumber = 0
endif

if exists("g:ywtxt_browserapp")
    let s:ywtxt_browserapp = g:ywtxt_browserapp
    unlet g:ywtxt_browserapp
endif
if exists("g:ywtxt_2htmlpre_usercmds")
    let s:ywtxt_2htmlpre_usercmds = g:ywtxt_2htmlpre_usercmds
endif
if exists("g:ywtxt_2htmlpost_usercmds")
    let s:ywtxt_2htmlpost_usercmds = g:ywtxt_2htmlpost_usercmds
endif

if exists("g:ywtxt_bib_entrytypes")
    let s:ywtxt_bib_entrytypes = g:ywtxt_bib_entrytypes
    unlet g:ywtxt_bib_entrytypes
else
    let s:ywtxt_bib_entrytypes = ["article", "book"]
endif
for t in s:ywtxt_bib_entrytypes
    if exists("g:ywtxt_bib_entries_{t}")
        let s:ywtxt_bib_entries_{t} = g:ywtxt_bib_entries_{t}
        unlet g:ywtxt_bib_entries_{t}
    else
        if t =~ '\carticle'
            let s:ywtxt_bib_entries_article = [
                        \['author','. '],
                        \['title','. '],
                        \['journal',', '],
                        \['year',', '],
                        \['volume',''],
                        \['number','(', ') :'],
                        \['pages','. '],
                        \]
        elseif t =~ '\cbook'
            let s:ywtxt_bib_entries_book = [
                        \['author','. '],
                        \['title','. '],
                        \['address',': '],
                        \['publisher',', '],
                        \['year','. '],
                        \]
        endif
    endif
endfor

if exists("g:ywtxt_headings_hl")
    let s:ywtxt_headings_hl = g:ywtxt_headings_hl
    unlet g:ywtxt_headings_hl
else
    " s:ywtxt_headings_hl = {'level':[[fg_on_dark_term, fg_on_light_term], [fg_on_dark_gui, fg_on_light_gui]]}
    let s:ywtxt_headings_hl = {
                \'1':[['blue', 'blue'],['LightSkyBlue', 'Blue1']],
                \'2':[['yellow', 'yellow'],['LightGoldenrod', 'DarkGoldenrod']],
                \'3':[['cyan', 'cyan'],['Cyan1', 'Purple']],
                \'4':[['red', 'red'],['red1', 'red']],
                \'5':[['green', 'green'],['PaleGreen', 'ForestGreen']],
                \'6':[['magenta', 'magenta'],['Aquamarine', 'CadetBlue']],
                \'7':[['blue', 'blue'],['LightSteelBlue', 'Orchid']],
                \'8':[['green', 'green'],['LightSalmon', 'RosyBrown']],
                \'9':[['blue', 'blue'],['LightSkyBlue', 'Blue1']],
                \'10':[['yellow', 'yellow'],['LightGoldenrod', 'DarkGoldenrod']],
                \}
endif

let s:ywtxt_toc_title_h = 2
let s:ywtxt_def_headingpat = '\%(\%(#\|\d\+\)\.\)*\%(#\|\d\+\)'

let s:ywtxt_htmlpretagsl = ['<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>', '<pre style="word-wrap: break-word; white-space: pre-wrap; white-space: -moz-pre-wrap" >']

function Ywtxt_FoldExpr(l) "{{{ Folding rule.
    let line=getline(a:l)
    if match(line, '^\s*% BEGINSNIP ywtxt') == 0
        if !exists("b:ywtxt_snip_in")
            let b:ywtxt_snip_in = 1
        else
            let b:ywtxt_snip_in += 1
        endif
        return 'a1'
    elseif match(line, '^\s*% BEGINSNIP') == 0
        return 'a1'
    elseif match(line, '^\s*% ENDSNIP') == 0
        if exists("b:ywtxt_snip_in")
            if b:ywtxt_snip_in == 1
                unlet b:ywtxt_snip_in
            else
                let b:ywtxt_snip_in -= 1
            endif
        endif
        return 's1'
    endif
    if exists("b:ywtxt_snip_in")
        return '='
    endif
    let headingp = <SID>Ywtxt_HeadingP(line)
    if headingp
        return '>' . headingp
    endif
    return '='
endfunction "}}}

function s:Ywtxt_WinJump(p,n) "{{{ Mom win <-> toc win
    " a:p: if change the position(1) or not(0); a:n: if wipeout the toc window(1) or not(0)
    let tocwp = match(bufname(""), '_.*_TOC_') + 1 " Detect if toc(1) or mom(0) window
    if tocwp
        let toclst = <SID>Ywtxt_GetHeadings(b:ywtxt_toc_type)
        let bufnr = bufnr(bufname(""))
        let bufwinnr = bufwinnr(b:ywtxt_toc_mom_bufnr)
        if bufwinnr
            let l = toclst[0][line('.') - 1 - s:ywtxt_toc_title_h][2]
            execute bufwinnr . 'wincmd w'
            if a:p
                execute 'normal ' . l . 'Gzvzz'
            endif
        endif
        if a:n
            execute 'bwipeout ' . bufnr
        endif
    else
        call <SID>Ywtxt_OpenTOC(b:toc_type)
    endif
endfunction "}}}

function s:Ywtxt_Jump2File(f,a,b) "{{{ Jump to file
    let bufwnr = bufwinnr(a:f)
    if !filereadable(a:f)
        return
    endif
    if bufwnr == -1
        execute 'keepalt split ' . a:f
    else
        execute bufwnr . 'wincmd w'
    endif
    if a:a != ''
        if search(a:a, 'w') == 0
            echohl ErrorMsg | echo "ywtxt: Unknown location! Try to find a normal string instead." | echohl NONE
            call search(a:b, 'w')
        endif
        normal zvzz
    endif
endfunction "}}}

function Ywtxt_OpenTOC(t) "{{{ Open and refresh toc.
    let toclst = <SID>Ywtxt_GetHeadings(a:t)
    if match(bufname(""), '_.*_TOC_') == 0 " toc window
        let cur_cursor = line('.')
        let filelst = getbufline(b:ywtxt_toc_mom_bufnr, 1, '$')
    else " For mom window
        let filelst = getbufline("", 1, '$')
        let bufnr = bufnr("")
        let bufname = expand("%:t:r")
        let cur_cursor = toclst[1] + s:ywtxt_toc_title_h
        let bufwnr = bufwinnr('_' . bufname . '_TOC_')
        if bufwnr == -1
            let tocwidth = (winwidth(bufwinnr(bufnr)) / 4)
            if exists("s:ywtxt_tocwidth")
                let tocwidth = s:ywtxt_tocwidth
            endif
            if exists("b:ywtxt_cus_headingslst")
                let ywtxt_cus_headingslst = b:ywtxt_cus_headingslst
            endif
            execute 'silent keepalt ' . tocwidth . 'vsplit _' .  bufname . '_TOC_'
            if exists("ywtxt_cus_headingslst")
                let b:ywtxt_cus_headingslst = ywtxt_cus_headingslst
            endif
            setlocal buftype=nofile
            setlocal bufhidden=hide
            setlocal noswapfile
            setlocal filetype=ywtxt
            execute 'setlocal textwidth=' . tocwidth
            let b:ywtxt_toc_mom_bufnr = bufnr
        elseif bufwnr != -1
            execute bufwnr . 'wincmd w'
        endif
    endif
    let toc_len = len(toclst[0])
    let toclns = ["§ " . a:t, repeat("-", len(a:t) + 5)] " cur_cursor. let s:ywtxt_toc_title_h = 2
    syntax match ywtxt_toc_title /\%^\_.\{-}\zs§ .*$/
    highlight default link ywtxt_toc_title Title
    for l in range(toc_len)
        call add(toclns, toclst[0][l][4] . toclst[0][l][1])
    endfor
    setlocal modifiable
    %d
    call setline(1, toclns)
    let b:ywtxt_toc_type = a:t
    execute 'normal ' . cur_cursor . 'Gzv'
    setlocal nomodifiable
endfunction "}}}

function Ywtxt_ToggleToc() "{{{ Toggle toc type
    let toctypelst = ['Contents', 'Figure', 'Table']
    let typeidx = index(toctypelst, b:ywtxt_toc_type)
    if typeidx != (len(toctypelst) - 1)
        let typeidx += 1
    else
        let typeidx = 0
    endif
    call Ywtxt_OpenTOC(toctypelst[typeidx])
endfunction "}}}

function s:Ywtxt_ReturnPairRegion(t) "{{{ Return pair region line numbers.
    let returnpair_save_cursor = getpos(".")
    let leftlist = []
    let rightlist = []
    if a:t == 'ref'
        let lp = "^% bibfile = '"
        let rp = "^% endbib"
    elseif a:t == 'snip'
        let lp = '^\s*% BEGINSNIP\s'
        let rp = '^\s*% ENDSNIP'
    endif
    execute 'silent g/' . lp . '/call add(leftlist, line("."))'
    execute 'silent g/' . rp . '/call add(rightlist, line("."))'
    call setpos('.', returnpair_save_cursor)
    return [leftlist, rightlist]
endfunction "}}}

function Ywtxt_SearchHeadingPat() "{{{ search heading patten
    if match(bufname(""), '_.*_TOC_') + 1 " Detect if toc(1) or mom(0) window
        return
    endif
    let cus_headings_disable = searchpos('^% HEADINGS NONE', 'cnw')[0]
    if cus_headings_disable
        return
    endif
    let cus_headings = matchstr(getline(searchpos('^% HEADINGS ', 'cnw')[0]), '^\s*% HEADINGS \+\zs.*\ze\s*$')
    if cus_headings != ''
        let headingslst = split(cus_headings, '[''"]\zs\s\+\ze[''"]')
    elseif exists("s:ywtxt_HeadingsPat")
        let headingslst = split(s:ywtxt_HeadingsPat, '[''"]\zs\s\+\ze[''"]')
    else
        return
    endif
    if len(headingslst) == 0
        return
    endif
    let last_headingpat = match(headingslst[-1][1:-2], '^\%(#\.\)*#$')
    if last_headingpat == -1
        let b:ywtxt_cus_headingslst = map(headingslst, 'v:val[1:-2]')
        let start_autoheadinglevel = 2
    else
        let b:ywtxt_cus_headingslst = map(headingslst[:-2], 'v:val[1:-2]')
        let start_autoheadinglevel = len(split(headingslst[-1], '\.'))
    endif
    call add(b:ywtxt_cus_headingslst, start_autoheadinglevel)
    " % HEADINGS "第#章" "第#节" "#." "#.#"
    " b:ywtxt_cus_headingslst = ["第#章", "第#节", "#.", 2] 2 means ywtxt will auto generate the levels from '#.#'.
endfunction "}}}

function s:Ywtxt_ReturnHeadingName(l) "{{{ Get heading name.
    " a:l: level.
    if exists("b:ywtxt_cus_headingslst")
        if len(b:ywtxt_cus_headingslst) > a:l
            return b:ywtxt_cus_headingslst[a:l - 1]
        else
            return repeat('#.', (a:l - b:ywtxt_cus_headingslst[-1] - 1)) . '#'
        endif
    endif
    return repeat('#.', (a:l - 1)) . '#'
endfunction "}}}

function s:Ywtxt_HeadingP(l,...) "{{{ Return the heading level, 0 if not.
    " a:1 == 1: force to assure current window is mom window.
    let line = a:l
    if match(bufname(""), '_.*_TOC_') == -1 || exists("a:1") " mom window
        let head = '^'
        let tail = '  '
    else
        let head = '^\s*'
        let tail = ' '
    endif
    let headinglen = len(split(matchstr(line, head . s:ywtxt_def_headingpat . '\ze' . tail), '\.'))
    if exists("b:ywtxt_cus_headingslst")
        if headinglen >= b:ywtxt_cus_headingslst[-1]
            return len(b:ywtxt_cus_headingslst[:-2]) + headinglen - 1
        else
            for i in range(len(b:ywtxt_cus_headingslst[:-2]))
                if match(line, head . substitute(escape(b:ywtxt_cus_headingslst[i], '\.'), '#', '\\%(\\d\\+\\|#\\)', '') . tail) == 0
                    return (i + 1)
                endif
            endfor
        endif
    endif
    return headinglen
endfunction "}}}

function s:Ywtxt_GetHeadings(t) "{{{ Get headings
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
        if match(line, '^\s*% BEGINSNIP\s') == 0
            if !exists("snip_in")
                let snip_in = 1
            else
                let snip_in += 1
            endif
        elseif match(line, '^\s*% ENDSNIP') == 0
            if snip_in == 1
                unlet snip_in
            else
                let snip_in -= 1
            endif
        endif
        if exists("snip_in")
            continue
        endif
        " TOC gerneration
        if a:t == 'Contents'
            let hlevel = <SID>Ywtxt_HeadingP(line, 1)
            if hlevel == 0
                continue
            endif
            " number generating
            if !exists("sec" . hlevel) || (secmaxlev < hlevel)
                execute 'let sec' . hlevel . '=1'
            else
                execute 'let sec' . hlevel . '+=1'
            endif
            let secmaxlev = hlevel
            " section display generating
            let startidx = 1
            if exists("b:ywtxt_cus_headingslst")
                let cus_headingslen = len(b:ywtxt_cus_headingslst) - 1
                if hlevel > cus_headingslen
                    let startidx = cus_headingslen + 1
                    if !exists("sec" . cus_headingslen)
                        let secnum = 0
                    else
                        execute 'let secnum = sec' . cus_headingslen
                    endif
                else
                    let headingname = <SID>Ywtxt_ReturnHeadingName(hlevel)
                    let headingnamepre = matchstr(headingname, '.*\ze#')
                    let headingnamepost = matchstr(headingname, '#\zs.*')
                    execute 'let secnum = headingnamepre .  sec' . hlevel . ' . headingnamepost'
                endif
            endif
            if !exists("b:ywtxt_cus_headingslst") || (hlevel > cus_headingslen)
                for li in range(startidx, hlevel)
                    if !exists("sec" . li)
                        if li == 1
                            let secnum = "0"
                        else
                            let secnum .= ".0"
                        endif
                    elseif li == 1
                        let secnum = sec1
                    else
                        execute 'let secnum .= "." . sec' . li
                    endif
                endfor
            endif
            let heading = matchstr(line, '^\%(.\{-}\ze  \)\{1}')
            let tail = matchstr(line, '^\%(.\{-}  \)\{1}\zs.*')
            let realsecnum = secnum . '  '
            let displaysecnum = repeat('  ', (hlevel - 1)) . secnum . ' '
        else " TODO Figure #-#., Table #-#.. First # is chapter number.
            if a:t == 'Figure'
                " Figure TOC gerneration
                let pat = '^\s*\%(\cFig\%(\.\|ure\)\|图\)\s\%(#\|\d\+\)\%(\|-\%(#\|\d\+\)\)\.\ze  '
            elseif a:t == 'Table'
                " Table TOC gerneration
                let pat = '^\s*\%(\cTable\|表\)\s\%(#\|\d\+\)\%(\|-\%(#\|\d\+\)\)\.\ze  '
            endif
            let heading = matchstr(line, pat)
            if heading == ''
                continue
            endif
            let hlevel = 1
            let tail = matchstr(line, '^\%(.\{-}  \)\{1}\zs.*')
            let realsecnum = ''
            let displaysecnum = heading . ' '
        endif
        if momlnum <= cur_cursor
            let n = len(toclst) + 1
        endif
        call add(toclst, [heading, tail, momlnum, realsecnum, displaysecnum, hlevel])
        " real line: heading(0) + tail(1). momlnum(2): file_mom current line number in Mom window. secnum(3): section number, display secnum(4): use in toc win to display; hlevel(5): level of section.
    endfor
    return [toclst, n] " n: curren section
endfunction "}}}

function Ywtxt_Dialog(t) "{{{ Dialog
    if a:t == 'CreatHeading'
        echohl MoreMsg | echo "Open New (P)arent/Current/(C)hild/(O)ther/(R)eference/(S)nip?" | echohl None
        let l = nr2char(getchar())
        if l =~ '[Pp]'
            call <SID>Ywtxt_CreateHeading('heading', -1)
        elseif l =~ '[Cc]'
            call <SID>Ywtxt_CreateHeading('heading', 1)
        elseif l =~ '[Oo]'
            let lev = input("Which level(<num>): ", '')
            if lev =~ '\d\+'
                call <SID>Ywtxt_CreateHeading('heading', lev)
            endif
        elseif l =~ '[Rr]'
            call <SID>Ywtxt_CreateHeading('Ref', 0)
        elseif l =~ '[Ss]'
            call <SID>Ywtxt_InsertSnip()
        else
            call <SID>Ywtxt_CreateHeading('heading', 0)
        endif
        return ''
    endif
endfunction "}}}

function s:Ywtxt_CreateHeading(t, l) "{{{ Create Heading.
    let fl = foldlevel(".")
    let ln = foldclosedend('.')
    if ln == -1
        let ln = line('.')
    endif
    if exists("b:ywtxt_cus_headingslst")
        let cus_headingslen = len(b:ywtxt_cus_headingslst) - 1
        if (fl + a:l) > 0
            if (fl + a:l) <= cus_headingslen
                let headingname = <SID>Ywtxt_ReturnHeadingName(fl + a:l)
                let headingnamepre = matchstr(headingname, '.*\ze#')
                let headingnamepost = matchstr(headingname, '#\zs.*')
                let heading = headingnamepre . '#' . headingnamepost . '  '
            else
                let heading = repeat('#.', (foldlevel(".") + a:l - cus_headingslen)) . '#  '
            endif
        else
            let headingname = <SID>Ywtxt_ReturnHeadingName(1)
            let headingnamepre = matchstr(headingname, '.*\ze#')
            let headingnamepost = matchstr(headingname, '#\zs.*')
            let heading = headingnamepre . '#' . headingnamepost . '  '
        endif
    elseif (fl + a:l) > 1
        let heading = repeat('#.', (foldlevel(".") + a:l - 1)) . '#  '
    else
        let heading = '#  '
    endif
    if a:t == 'heading'
        execute ln . "put ='" . heading . "'"
    elseif a:t == 'ref'
        setlocal nofoldenable
        call append(ln, ["% bibfile = '" . input("Bib file? ", './', 'file') . "'", '', '% endbib'])
        normal jj
        setlocal foldenable
        normal zv
        return
    endif
    if s:ywtxt_autonumber
        let save_cursor = getpos(".")
        let toclst = <SID>Ywtxt_GetHeadings('Contents')
        for l in toclst[0]
            call setline(l[2], l[3] . l[1])
        endfor
        call setpos('.', save_cursor)
    endif
    normal zv
    startinsert!
endfunction "}}}

function Ywtxt_toc_cmd(op,pos,jumpp,tocd,...) "{{{ command on mom file in toc window.
    " a:op: operation name. a:pos: operation can conduct on the title? a:jumpp,a:tocd: parameter passed to winjump()
    if  (match(bufname(""), '_.*_TOC_') == -1) || ((a:pos == 0) && (line('.') <= s:ywtxt_toc_title_h)) || (line('$') == s:ywtxt_toc_title_h)
        return
    endif
    let toc_save_cursor = getpos(".")
    if a:op =~ '\%(syncheading\|reindent\)'
        let toclst = <SID>Ywtxt_GetHeadings('Contents')
    endif
    if a:op == 'unfold' " jump
        normal zR
    elseif a:op == 'toggleFolding' " Folding toggle
        if exists('b:ywtxt_foldingAll') && b:ywtxt_foldingAll == line('.')
            unlet b:ywtxt_foldingAll
            normal zR
        else
            let b:ywtxt_foldingAll = line('.')
            let ywtxt_foldingAll = b:ywtxt_foldingAll
            normal zMzv
        endif
    elseif a:op == 'outlinemove' " move and outline
        execute 'normal ' . a:1 . 'zMzv'
    elseif a:op == 'reindent'
        let startline=line(".")
        let curln = startline + 1
        let prevlevel = foldlevel(startline - 1)
        let level = foldlevel('.')
        let endline = line('$')
        while (foldlevel(curln) > level) && (curln <= endline)
            let curln += 1
        endwhile
        let curln -= 1
    endif
    call <SID>Ywtxt_WinJump(a:jumpp,a:tocd)
    let save_cursor = getpos(".")
    if a:op == 'jump' " jump
        if a:jumpp
            return
        endif
    elseif a:op == 'unfold' " unfold
        normal zR
    elseif a:op == 'outlinemove' " move and outline
        normal zMzv
    elseif a:op == 'undo' " undo
        silent! undo
    elseif a:op == 'redo' " redo
        silent! redo
    elseif a:op == 'save' " save buffer
        write
    elseif a:op == '2html' " Export to html.
        silent call <SID>Ywtxt_ToHtml()
        return
    elseif a:op == 'syncheading' " Sync with the heading number.
        for l in toclst[0]
            call setline(l[2], l[3] . l[1])
        endfor
    elseif a:op == 'reindent'
        let n = 1
        for i in toclst[0][startline - 1 - s:ywtxt_toc_title_h : curln - 1 - s:ywtxt_toc_title_h]
            if a:1 == 'l' && level > 1
                call setline(i[2], <SID>Ywtxt_ReturnHeadingName(i[5] - 1) . '  ' . i[1])
            elseif a:1 == 'r' && (level <= prevlevel)
                call setline(i[2], <SID>Ywtxt_ReturnHeadingName(i[5] + 1) . '  ' . i[1])
            endif
        endfor
    elseif a:op == 'genrefs' " Generate Bibliography.
        echohl ErrorMsg | echo "This operation will generate the References section, all lines in the references setion will be deleted, you've been warned!"
        echohl MoreMsg | echo "Are you sure? (Y)es/(N)o" | echohl None
        if getchar() =~ '\%(121\|89\)'
            call <SID>Ywtxt_GenBibliography()
        endif
    elseif a:op == 'toggleFolding' " Folding toggle
        if exists('ywtxt_foldingAll')
            normal zMzv
        else
            normal zR
        endif
    endif
    if a:jumpp
        call setpos('.', save_cursor)
    endif
    wincmd p
    if a:op =~ '\%(genrefs\|reindent\|undo\|redo\)'
        silent call Ywtxt_OpenTOC('Contents')
    endif
    call setpos('.', toc_save_cursor)
endfunction "}}}

function Ywtxt_keymaps() "{{{ key maps.
    nmap <silent> <buffer> <Tab> :call Ywtxt_Tab('t')<CR>
    nmap <silent> <buffer> <Leader>t :call Ywtxt_OpenTOC('Contents')<CR>
    if match(bufname(""), '_.*_TOC_') == -1 " For mom window
        nmap <silent> <buffer> <C-j> :call Ywtxt_Dialog("CreatHeading")<CR>
        nmap <silent> <buffer> <Leader>q :execute 'silent! bwipeout ' . bufnr('_' . expand("%:t:r") . '_TOC_')<CR>
        nmap <silent> <buffer> <Leader><tab> :execute 'silent! ' . bufwinnr('_' . expand("%:t:r") . '_TOC_') . 'wincmd w'<CR>
        nmap <silent> <buffer> <CR> :call Ywtxt_Tab('e')<CR>
        imap <silent> <buffer> <C-j> <C-R>=Ywtxt_Dialog("CreatHeading")<CR>
        imap <silent> <buffer> ^{ ^{}<Left>
        imap <silent> <buffer> ^[ ^[]<Left>
        imap <silent> <buffer> _{ _{}<Left>
    else " For toc window
        nmap <silent> <buffer> t :call Ywtxt_ToggleToc()<CR>
        nmap <silent> <buffer> J :call Ywtxt_toc_cmd('outlinemove', 0, 1, 0, 'j')<CR>
        nmap <silent> <buffer> K :call Ywtxt_toc_cmd('outlinemove', 0, 1, 0, 'k')<CR>
        nmap <silent> <buffer> q :bwipeout<CR>
        nmap <silent> <buffer> r :call Ywtxt_OpenTOC(b:ywtxt_toc_type)<CR>
        nmap <silent> <buffer> <Space> :call Ywtxt_toc_cmd('jump', 0, 0, 0)<CR>
        nmap <silent> <buffer> <Enter> :call Ywtxt_toc_cmd('jump', 0, 1, 0)<CR>
        nmap <silent> <buffer> X :call Ywtxt_toc_cmd('toggleFolding', 0, 1, 0)<CR>
        nmap <silent> <buffer> x :call Ywtxt_toc_cmd('jump', 0, 1, 1)<CR>
        nmap <silent> <buffer> <leader>< :call Ywtxt_toc_cmd('reindent', 1, 1, 0, 'l')<CR>
        nmap <silent> <buffer> <leader>> :call Ywtxt_toc_cmd('reindent', 1, 1, 0, 'r')<CR>
        nmap <silent> <buffer> u :call Ywtxt_toc_cmd('undo', 1, 0, 0)<CR>
        nmap <silent> <buffer> <c-r> :call Ywtxt_toc_cmd('redo', 1, 0, 0)<CR>
        nmap <silent> <buffer> w :call Ywtxt_toc_cmd('save', 1, 0, 0)<CR>
        nmap <silent> <buffer> <Leader><tab> :execute 'silent! ' . bufwinnr(b:ywtxt_toc_mom_bufnr) . 'wincmd w'<CR>
        nmap <silent> <buffer> S :call Ywtxt_toc_cmd('syncheading', 1, 0, 0)<CR>
        nmap <silent> <buffer> B :call Ywtxt_toc_cmd('genrefs', 1, 0, 0)<CR>
        nmap <silent> <buffer> E :call Ywtxt_toc_cmd('2html', 1, 0, 1)<CR>
        nmap <silent> <buffer> A :call Ywtxt_toc_cmd('unfold', 0, 0, 0)<CR>
    endif
endfunction "}}}

function Ywtxt_Tab(k) "{{{ Function for <tab> and <enter>
    let refslnlst = <SID>Ywtxt_ReturnPairRegion('ref')
    let refsnuml = len(refslnlst[0])
    let refsnumr = len(refslnlst[1])
    if (refsnuml == refsnumr) && (refsnuml != 0)
        let refsnum = refsnuml
    else
        let refsnum = 0
    endif
    let line = getline('.')
    let lnum = line('.')
    if refsnum
        for i in range(refsnum)
            if (lnum > refslnlst[0][i]) && (lnum < refslnlst[1][i]) " Ref region
                let num = lnum - searchpos("% bibfile = '", 'bnW')[0]
                " Determine which region to get refs
                if i == 0
                    let ls = 1
                else
                    let ls = refslnlst[1][i-1] + 1
                endif
                let le = refslnlst[0][i] - 1
                let refsdic = <SID>Ywtxt_GetRefLst(ls, le) " FIXME multi bib region.
                if a:k == 't'
                    call search('\^\[[^]]*\<\zs' . refsdic[num][0] . '\>[^]]*\]', 'bW', ls)
                    normal zv
                elseif a:k == 'e'
                    call <SID>Ywtxt_OpenBibFile(refsdic[num][0])
                endif
                return
            endif
        endfor
    endif
    let kwd = escape(expand('<cword>'), '~')
    if match(line, '\^\[[^]]*' . kwd . '[^]]*\]') != -1
        if a:k == 't'
            echohl MoreMsg | echo <SID>Ywtxt_GetBibEntry(kwd) | echohl None
        elseif a:k == 'e'
            call <SID>Ywtxt_OpenBibFile(kwd)
        endif
        return
    elseif match(line, '\*\[[^]]*\]') != -1 " cross-reference
        let endidx = len(line)
        let cur = col('.')
        let start = cur - 1
        let end = cur
        while 1
            if start <= 2 && line[start - 1] != '['
                let start = cur
                break
            elseif line[start - 1] == '['
                break
            endif
            let start -= 1
        endwhile
        while 1
            if end >= endidx
                if (line[end - 1] != ']')
                    let end = cur
                endif
                break
            elseif (line[end - 1] == ']')
                break
            endif
            let end += 1
        endwhile
        if (cur > start) && (cur < end)
            let hyper = line[start : end - 2]
            if a:k == 'e' && (hyper != '')
                let hyperfile = expand(matchstr(hyper, '^[^#]*'))
                let hyperanchor = escape(matchstr(hyper, '#\zs.*$'), '\')
                if (hyperfile == '') && (hyperanchor != '')
                    let hyperfile = expand('%')
                endif
                if filereadable(hyperfile)
                    if hyperanchor =~ '[^\x00-\xff]'
                        call <SID>Ywtxt_Jump2File(hyperfile, '\*\@<!\zs\V[#' . hyperanchor . ']', '\%(\*\[#\)\@<!\zs\V' . hyperanchor)
                    else
                        call <SID>Ywtxt_Jump2File(hyperfile, '\*\@<!\zs\V[#' . hyperanchor . ']', '\%(\*\[#\)\@<!\zs\V\<' . hyperanchor . '\>')
                    endif
                    return
                endif
            endif
        endif
    endif
    if a:k == 't'
        silent! normal za
    elseif a:k == 'e'
        normal j
    endif
endfunction "}}}

function s:Ywtxt_ToHtml(...) "{{{ ywtxt to html FIXME: ugly.
    if exists("b:ywtxt_cus_headingslst")
        let ywtxt_cus_headingslst = b:ywtxt_cus_headingslst
    endif
    let save_bufname = expand("%:p")
    let save_tmpbufname = expand("%:p:r") . '_ywtxt'
    execute 'keepalt saveas! ' . expand('%:r') . '_ywtxt'
    set filetype=ywtxt
    normal gg0
    execute 'g/^% input .*/keepalt read ' . expand(matchstr(getline(3), 'input\s*\zs.*$'))
    let refsdic = <SID>Ywtxt_GetRefLst(1, '$')
    g/^\s*%/delete " Delete the comment line
    normal zR
    if exists("a:1")
        let ls = a:1
        let le = a:2
    else
        let ls = 1
        let le = line('$')
    endif
    if exists("s:ywtxt_2htmlpre_usercmds")
        for c in s:ywtxt_2htmlpre_usercmds
            execute c
        endfor
    endif
    write
    execute 'keepalt ' . ls . ',' . le . 'TOhtml'
    " level Headings
    let headinghead = ''
    if &number
        let headinghead = '\%(<[^>]*>\)\+[^<]*\d\+\s*\%(<[^>]*>\)*<\/font>\zs'
    endif
    if exists("ywtxt_cus_headingslst")
        let headlen = len(ywtxt_cus_headingslst) - 1
        if headlen < 3
            for i in range(1, headlen)
                execute '%s/^' .  headinghead . '\(\%(<[^>]\+>\)*' . substitute(escape(ywtxt_cus_headingslst[i-1], '\.'), '#', '\\%(\\d\\+\\|#\\)', '') . '&nbsp;&nbsp;.*$\)/<h' . (i+1) . '>\1<\/h' . (i+1) . '>/e'
            endfor
            for i in range(headlen + 1, 3)
                execute '%s/^' . headinghead . '\(\%(<[^>]\+>\)*\%(\%(#\|\d\+\)\.\)\{' . (i - ywtxt_cus_headingslst[-1] - 1) . '}\%(#\|\d\+\)&nbsp;&nbsp;.*$\)/<h' . (i+1) . '>\1<\/h' . (i+1) . '>/e'
            endfor
            execute '%s/^' . headinghead . '\(\%(<[^>]\+>\)*\%(\%(#\|\d\+\)\.\)\{' . (ywtxt_cus_headingslst[-1] - 1) . ',}\%(#\|\d\+\)&nbsp;&nbsp;.*\)/<h4>\1<\/h4>/e'
        elseif headlen == 3
            for i in range(1, headlen)
                execute '%s/^' . headinghead . '\(\%(<[^>]\+>\)*' . substitute(escape(ywtxt_cus_headingslst[i-1], '\.'), '#', '\\%(\\d\\+\\|#\\)', '') . '&nbsp;&nbsp;.*$\)/<h' . (i+1) . '>\1<\/h' . (i+1) . '>/e'
            endfor
            execute '%s/^' . headinghead . '\(\%(<[^>]\+>\)*\%(\%(#\|\d\+\)\.\)\{' . (ywtxt_cus_headingslst[-1] - 1) . ',}\%(#\|\d\+\)&nbsp;&nbsp;.*\)/<h4>\1<\/h4>/e'
        else
            for i in range(1, 2)
                execute '%s/^' . headinghead . '\(\%(<[^>]\+>\)*' . substitute(escape(ywtxt_cus_headingslst[i-1], '\.'), '#', '\\%(\\d\\+\\|#\\)', '') . '&nbsp;&nbsp;.*$\)/<h' . (i+1) . '>\1<\/h' . (i+1) . '>/e'
            endfor
            for i in range(3, headlen)
                execute '%s/^' . headinghead . '\(\%(<[^>]\+>\)*' . substitute(escape(ywtxt_cus_headingslst[i-1], '\.'), '#', '\\%(\\d\\+\\|#\\)', '') . '&nbsp;&nbsp;.*$\)/<h' . (i+1) . '>\1<\/h' . (i+1) . '>/e'
            endfor
        endif
        execute '%s/^' . headinghead . '\(\%(<[^>]\+>\)*\%(\%(#\|\d\+\)\.\)\{' . (headlen + 1) . ',}\%(#\|\d\+\)&nbsp;&nbsp;.*\)/<h4>\1<\/h4>/e'
    else
        for i in range(1, 3) " For normal heading pattern
            execute '%s/^' . headinghead . '\(\%(<[^>]\+>\)*\%(\%(#\|\d\+\)\.\)\{' . (i-1) . '}\%(#\|\d\+\)&nbsp;&nbsp;.*$\)/<h' . (i+1) . '>\1<\/h' . (i+1) . '>/e'
        endfor
        execute '%s/^' . headinghead . '\(\%(<[^>]\+>\)*\%(\%(#\|\d\+\)\.\)\{4,}\%(#\|\d\+\)&nbsp;&nbsp;.*\)/<h4>\1<\/h4>/e'
    endif
    %s/<b>\zs\*\([^<]*\)\*\ze</\1/ge " boldface
    %s/<i>\zs\/\([^<]*\)\/\ze</\1/ge " italic
    %s/<u>\zs_\([^<]*\)_\ze</\1/ge " underlined
    if len(refsdic) != 0
        for i in range(1, len(refsdic))
            execute '%s/\^\[\zs' . refsdic[i][0] . '\ze\]/' . i . '/ge'
        endfor
    endif
    %s/\^{\([^}]\+\)}/<sup>\1<\/sup>/ge " superscript html
    %s/_{\([^}]\+\)}/<sub>\1<\/sub>/ge " subscript html
    %s/\^\(\[[^]]\+\]\|{[^}]\+}\)/<sup>\1<\/sup>/ge " superscript citing number html
    %s/\[\s*\f*\.\%(jpg\|png\|bmp\|gif\)\s*\]/\='<img src=' . substitute(submatch(0)[1 : -2], '\s', '%20', 'g') . '>'/gei " pictures
    write
    if exists("s:ywtxt_browserapp") && executable(s:ywtxt_browserapp)
        if has("unix")
            execute '!' . s:ywtxt_browserapp . ' ' . expand('%:r') . '.html' . ' &'
        elseif has("win32")
            execute '!START ' . s:ywtxt_browserapp . ' ' . expand('%:r') . '.html' . ' &'
        endif
    endif
    bwipeout | redraw!
    if exists("s:ywtxt_2htmlpost_usercmds")
        for c in s:ywtxt_2htmlpost_usercmds
            execute c
        endfor
    endif
    execute 'silent! buffer ' . bufnr(save_bufname) . '| bwipeout! ' . bufnr(save_tmpbufname)
    call delete(save_tmpbufname)
    normal zvzz
    call Ywtxt_OpenTOC('Contents')
endfunction "}}}
" command -bar -range=% YwtxtTOhtml call Ywtxt_ToHtml(<line1>,<line2>)

"{{{ bib supports
function s:Ywtxt_OpenBibFile(w) " {{{ Open bib file.
    let bibfile = expand(matchstr(getline(searchpos("^% bibfile = '", 'bnw')[0]), '^% bibfile = ''\zs[^'']*'))
    call <SID>Ywtxt_Jump2File(bibfile,'{' . a:w . '\>','')
endfunction "}}}

function s:Ywtxt_GetBibEntry(...) " {{{ Show bib entry
    if exists("a:1")
        let ywbib_cur_bibentry = a:1
    else
        let ywbib_cur_bibentry = expand("<cword>")
    endif
    let bibfile = expand(matchstr(getline(searchpos("^% bibfile = '", 'bnw')[0]), '^% bibfile = ''\zs[^'']*'))
    if !filereadable(bibfile)
        if !exists("a:1")
            echo 'No bib file found'
        endif
        return
    endif
    let bufnr = bufnr(bibfile)
    if bufnr == -1
        let bibfilelist = readfile(bibfile)
    else
        let bibfilelist = getbufline(bufnr, 1, '$')
    endif
    let entrysi = match(bibfilelist, '{' . ywbib_cur_bibentry . '\>,') " index of entry start
    if entrysi == -1
        if !exists("a:1")
            echo 'No bib found'
        endif
        return
    endif
    let entryei = match(bibfilelist, '^\s*}$', entrysi) " index of entry end
    let entrytype = matchstr(bibfilelist[entrysi], '@\zs[^{]*') " entry name
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
                if match(bibfile, '\%(/\|\d:\)') == 0
                    silent! call Ywrun_run(expand(bibentriesdic['url']))
                else
                    silent! call Ywrun_run(matchstr(bibfile, '.*/\ze.*$') . expand(bibentriesdic['url']))
                endif
            endif
        endif
    endif
    let entryshow = ""
    let ti = match(s:ywtxt_bib_entrytypes, '\c' . entrytype)
    if ti != -1
        let entries = s:ywtxt_bib_entries_{s:ywtxt_bib_entrytypes[ti]}
    endif
    for entry in entries
        if has_key(bibentriesdic, entry[0])
            if entry[0] =~ '\cauthor'
                let temp_entryshow = substitute(bibentriesdic[entry[0]], '\s*and\s*', ', ', 'g')
                let temp_entryshowlst = split(temp_entryshow, ', ')
                if len(temp_entryshowlst) < 4
                    let entryshow .= temp_entryshow . entry[1]
                else
                    if match(temp_entryshowlst[0], '\a') != -1
                        let etc = ' et. al'
                    else
                        let etc = '等'
                    endif
                    let entryshow .= join(temp_entryshowlst[0 : 2], ', ') . etc . entry[1]
                endif
            elseif len(entry) == 2
                let entryshow .= bibentriesdic[entry[0]] . entry[1]
            elseif len(entry) == 3
                let entryshow .= entry[1] . bibentriesdic[entry[0]] . entry[2]
            endif
        endif
    endfor
    if exists("a:1")
        return entryshow
    else
        echohl ErrorMsg
        echo entryshow
        echohl None
    endif
endfunction "}}}

function s:Ywtxt_GenBibliography() "{{{ Generate bibliography.
    let save_cursor = getpos(".")
    let refslnlst = <SID>Ywtxt_ReturnPairRegion('ref')
    let refsnum = len(refslnlst[0])
    if refsnum == 0
        return
    endif
    setlocal nofoldenable
    for i in range(refsnum)
        if (refslnlst[0][i] == 0) || (refslnlst[1][i] == 0) || (refslnlst[1][i] < (refslnlst[0][i] + 1))
            echohl ErrorMsg | echo "The section " . refsnum . " references not found, see the document to make .bib support work." | echohl None
            return
        endif
        if i == 0
            let ls = 1
        else
            let ls = refslnlst[1][i-1]
        endif
        let le = refslnlst[0][i] - 1
        let reflns = []
        let dic = <SID>Ywtxt_GetRefLst(ls, le)
        for l in range(1, len(dic))
            if exists("g:ywtxt_bib_nump") && g:ywtxt_bib_nump == 0
                call add(reflns, dic[l][1])
            else
                call add(reflns, '['. l . '] ' . dic[l][1])
            endif
        endfor
        let reflns = reflns + ['% endbib']
        execute (refslnlst[0][i] + 1) . ',' . refslnlst[1][i] . 'delete'
        call append(refslnlst[0][i], reflns)
        let offset = len(reflns) - refslnlst[1][i] + refslnlst[0][i]
        if i < refsnum
            let refslnlst[0][i+1] += offset
            let refslnlst[1][i+1] += offset
        endif
    endfor
    setlocal foldenable
    call setpos('.', save_cursor)
endfunction "}}}

function s:Ywtxt_GetRefLst(s, e) "{{{ Get bibs
    let getref_save_cursor = getpos(".")
    let s = a:s
    let e = a:e
    let biblines = []
    let biblst=[]
    execute s . ',' . e . 'g/\^\[[^]]*\]/call add(biblines, getline("."))'
    for line in biblines
        for bibs in filter(split(line, '\%(\ze\^\[\|\]\zs\)'), "v:val =~ '\\^\\[[^]]*\\]'")
            for bib in split(substitute(bibs[2:-2], '\s\+', '', 'g'), ',')
                if index(biblst, bib) == -1
                    call add(biblst, bib)
                endif
            endfor
        endfor
    endfor
    let refsdic = {}
    let n = 1
    for e in biblst
        let ent = <SID>Ywtxt_GetBibEntry(e)
        if ent !~ '^\%(\s*\|0\)$'
            let refsdic[n] = [e, ent]
            " n: number, starts from 1. e(0): keyword, ent(1): generated reference show.
            let n += 1
        endif
    endfor
    call setpos('.', getref_save_cursor)
    return refsdic
endfunction "}}}
"}}}

"{{{ snip
function s:Ywtxt_InsertSnip() "{{{ Insert snip.
    echohl ModeMsg
    let ftsnip = input("snip type: ", "", "customlist,Ywtxt_ListFt")
    echohl None
    setlocal nofoldenable
    call append('.', ['% BEGINSNIP ' . ftsnip, "", '% ENDSNIP'])
    normal jj
    setlocal foldenable
    normal zv
    call <SID>Ywtxt_SynSnip(ftsnip)
    startinsert
endfunction "}}}

function Ywtxt_ListFt(A,L,P) "{{{ Completion func for snip filetypes to insert in cmdline
    let comp = {}
    for p in split(&runtimepath, ',')
        for f in split(globpath(p.'/syntax/', '*.vim'), '\n')
            let ft = matchstr(f, '[^/]*\ze\.vim$')
            if match(ft, '^'.a:L) != -1
                let comp[ft] = ''
            endif
        endfor
    endfor
    return keys(comp)
endfunction "}}}

function Ywtxt_FindSnipft() "{{{ Check the Snip filetypes
    let save_cursor = getpos(".")
    normal gg
    let snipl = searchpos('^\s*% BEGINSNIP ', 'W')[0]
    let snipdic = {}
    while snipl
        let snipname = matchstr(getline(snipl), '^\s*% BEGINSNIP \zs\S\+')
        let snipdic[snipname] = 1
        let snipl = searchpos('^\s*% BEGINSNIP', 'W')[0]
    endwhile
    for snip in keys(snipdic)
        call <SID>Ywtxt_SynSnip(snip)
    endfor
    call setpos('.', save_cursor)
endfunction "}}}
"}}}

" {{{ syntax & highlight
function Ywtxt_Syntax_HeadingsPat() "{{{ Syntax the patten of headings. FIXME: ugly.
    if exists("b:ywtxt_cus_headingslst")
        if match(bufname(""), '_.*_TOC_') == -1 " mom window
            let head = '^'
            let tail = '  '
            for i in range(1, len(b:ywtxt_cus_headingslst) - 1)
                execute 'syntax match ywtxt_heading' . i . ' /' . head . substitute(escape(b:ywtxt_cus_headingslst[i-1], '\.'), '#', '\\%(\\d\\+\\|#\\)', '') . tail . '.*/ contains=CONTAINED'
            endfor
            for ei in range(len(b:ywtxt_cus_headingslst), 10)
                execute 'syntax match ywtxt_heading'. ei .' /' . head . '\%(\%(#\|\d\+\)\.\)\{'.(ei - b:ywtxt_cus_headingslst[-1] - 1).'}\%(#\|\d\+\)' . tail . '.*/ contains=CONTAINED'
            endfor
        else " toc window
            let head = '^\s'
            let tail = ' '
            for i in range(1, len(b:ywtxt_cus_headingslst) - 1)
                execute 'syntax match ywtxt_heading' . i . ' /' . head . '\{' . (2 * (i - 1)) . '}' . substitute(escape(b:ywtxt_cus_headingslst[i-1], '\.'), '#', '\\%(\\d\\+\\|#\\)', '') . tail . '.*/ contains=CONTAINED'
            endfor
            for ei in range(len(b:ywtxt_cus_headingslst), 10)
                execute 'syntax match ywtxt_heading'. ei .' /' . head . '\{' . (2 * (ei - 1)) . '}\%(\%(#\|\d\+\)\.\)\{'.(ei - b:ywtxt_cus_headingslst[-1] - 1).'}\%(#\|\d\+\)' . tail . '.*/ contains=CONTAINED'
            endfor
        endif
    else
        if match(bufname(""), '_.*_TOC_') == 0 " For toc window
            for i in range(1,10)
                execute 'syntax match ywtxt_heading'.i.' /^\s\{' . (2 * (i - 1)) . '}\%(\%(#\|\d\+\)\.\)\{'.(i - 1).'}\%(#\|\d\+\)\s.*/ contains=CONTAINED'
            endfor
        else " For mom window
            for i in range(1,10)
                execute 'syntax match ywtxt_heading'.i.' /^\%(\%(#\|\d\+\)\.\)\{' . (i - 1) . '}\%(#\|\d\+\)  .*/ contains=CONTAINED'
            endfor
        endif
    endif
endfunction "}}}

function Ywtxt_highlightheadings() "{{{ Highlight headings
if &background == "dark"
    for i in range(1, len(s:ywtxt_headings_hl))
        execute 'highlight ywtxt_heading' . i . ' ctermfg=' . s:ywtxt_headings_hl[i][0][0] . ' cterm=bold guifg=' . s:ywtxt_headings_hl[i][1][0] . ' gui=bold'
    endfor
else
    for i in range(1, len(s:ywtxt_headings_hl))
        execute 'highlight ywtxt_heading' . i . ' ctermfg=' . s:ywtxt_headings_hl[i][0][1] . ' cterm=bold guifg=' . s:ywtxt_headings_hl[i][1][1] . ' gui=bold'
    endfor
endif
endfunction "}}}

function s:Ywtxt_SynSnip(ftsnip,...) "{{{ Syntax for snip
    if !exists('b:ywtxt_ftsnipsdic')
        let b:ywtxt_ftsnipsdic = {}
    endif
    if !has_key(b:ywtxt_ftsnipsdic, a:ftsnip)
        let begin = '^\s*% BEGINSNIP ' . a:ftsnip
        let end = '^\s*% ENDSNIP'
        if exists("a:1")
            let begin = a:1
        endif
        if exists("a:2")
            let end = a:2
        endif
        if exists("b:current_syntax")
            let oldcurrent_syntax = b:current_syntax
            unlet b:current_syntax
        endif
        execute 'syntax include @ywtxt_snip' . a:ftsnip . ' syntax/' . a:ftsnip . '.vim'
        execute 'syntax region ywtxt_snip' . a:ftsnip . 'Snip matchgroup=Comment start="' . begin . '" end="' . end . '" contains=@ywtxt_snip' . a:ftsnip
        let b:ywtxt_ftsnipsdic[a:ftsnip] = ''
        unlet b:current_syntax
        if exists("oldcurrent_syntax")
            let b:current_syntax = oldcurrent_syntax
        endif
    endif
endfunction "}}}
" }}}
" TODO autocmd InsertLeave *.ywtxt refresh toc
" vim: foldmethod=marker:
