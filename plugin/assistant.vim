" == "acomment" == {{{
"
"          File:  assistant.vim
"          Path:  ~/.vim/plugin
"        Author:  A-yu
"      Modifier:  A-yu
"      Modified:  2012-05-03
"       License:  Public Domain
"   Description:  1. Display the definition of functions, variables, etc.
"                 2. Complete keywords(<C-x><C-u>).
"
" --}}}

" Exit if already loaded
if exists("g:loaded_assistant")
    finish
endif
let g:loaded_assistant = "Version 1.5"

" ================================== Conf {{{ ==================================
"
nmap <silent> <unique> <C-k> :call <SID>Help()<Cr>
"
" Mapping for Eclipse user
" imap <silent> <unique> <A-/> <C-x><C-u>
" nmap <silent> <unique> <A-/> :call <SID>Help()<Cr>
"
" Mapping for Netbeans user
" imap <silent> <unique> <C-\> <C-x><C-u>
" nmap <silent> <unique> <C-\> :call <SID>Help()<Cr>

let s:aType = {
            \'phps':'php', 'phtml':'php',
            \'vimrc':'vim'
            \}

let s:aChar = '[a-zA-Z0-9_]'
let s:aTags = '[f]'

let s:aPath = {}
let s:aDict = {}
" ================================== }}} Conf ==================================

" ================================== Apis {{{ ==================================
function! AGetUserDict(...)
    if a:0 < 1
        return s:aDict
    endif

    return s:Init(a:1) ? s:aDict[a:1] : {}
endf

function! ASetCompFunc(...)
    let type = a:0 > 0 ? a:1 : s:Fext()

    if !has_key(s:aType, type)
        if filereadable(expand(substitute(globpath(&rtp, 'plugin/assistant/'), "\n", ',', 'g').type.'.dict.txt'))
            let s:aType[type] = type
        endif
    endif

    if has_key(s:aType, type)
        set cfu=AutoCompFunc
    endif
endf

function! AutoCompFunc(start, base)
    if a:start
        let line = getline('.')
        let start = col('.') - 1
        while start > 0 && line[start - 1] =~ s:aChar
            let start -= 1
        endwhile
        return start
    else
        let fext = s:Fext()
        if !s:Init(fext) || a:base =~ '^\s*$'
            return []
        endif

        let tags = {}
        let tlst = taglist(a:base)
        let tlen = len(tlst) - 1
        while tlen >= 0
            if tlst[tlen]['name'] =~ '^'.a:base.s:aChar.'*$'
                let tags[tlst[tlen]['name']] = 1
            endif
            let tlen -= 1
        endw
        unl tlst tlen

        let dlst = []
        let keys = keys(s:aDict[s:aType[fext]])
        let vals = values(s:aDict[s:aType[fext]])
        let dlen = len(keys) - 1
        while dlen >= 0
            if keys[dlen] =~ '^'.a:base.s:aChar.'*$'
                if has_key(tags, keys[dlen])
                    call remove(tags, keys[dlen])
                endif

                call add(dlst, {'word':keys[dlen], 'menu':vals[dlen]})
            endif
            let dlen -= 1
        endw
        unl keys vals dlen

        return sort(keys(tags)) + sort(dlst)
    endif
endf
" ================================== }}} Apis ==================================

" ================================== }}} Main ==================================
function s:Fext()
    return tolower((strridx(expand("%"),".") == -1) ? "" : strpart(expand("%"),(strridx(expand("%"),".") + 1)))
endf

function s:Init(fext)
    if !has_key(s:aType, a:fext)
        return 0
    endif

    if !has_key(s:aPath, s:aType[a:fext])
        let s:aPath[s:aType[a:fext]] = expand(substitute(globpath(&rtp, 'plugin/assistant/'), "\n", ',', 'g').s:aType[a:fext].'.dict.txt')
    endif

    if !has_key(s:aDict, s:aType[a:fext])
        let s:aDict[s:aType[a:fext]] = {}
        for line in readfile(s:aPath[s:aType[a:fext]])
            let mList = matchlist(line, '^\s*\([^ ]\+\)\s*=>\s*\(.\+\)$')
            if len(mList) >= 3
                let s:aDict[s:aType[a:fext]][mList[1]] = mList[2]
            endif
        endfor
    endif

    return 1
endf

function s:Help()
    let fext = s:Fext()
    if !s:Init(fext)
        echo 'assistant.MISS : Does not support the file type "'.fext.'"'
        return
    endif

    let str = getline(".")
    let col = col(".")
    let end = col("$")

    let num = col - 1
    while num >= 0
        if strpart(str, num, 1) !~ s:aChar
            break
        endif
        let lcol = num
        let num -= 1
    endw
    if !exists("lcol")
        echo 'assistant.ERR : The current contents of the cursor is not a keyword'
        return
    endif

    let num = col - 1
    while num <= end
        if strpart(str, num, 1) !~ s:aChar
            break
        endif
        let rcol = num
        let num += 1
    endw

    let key = strpart(str, lcol, rcol-lcol+1)
    let len = len(s:aDict[s:aType[fext]]) - 1
    let keys = keys(s:aDict[s:aType[fext]])
    let vals = values(s:aDict[s:aType[fext]])

    let list = []

    let tlst = taglist(key)
    let tlen = len(tlst) - 1
    while tlen >= 0
        if tlst[tlen]['name'] == key && tlst[tlen]['kind'] =~ s:aTags
            call add(list, tlst[tlen]['cmd'] . '    ' . pathshorten(tlst[tlen]['filename']))
        endif
        let tlen -= 1
    endw

    while len >= 0
        if keys[len] == key || keys[len] =~ '^.\+\.'.key.'$' || keys[len] =~ '^.\+:\{2}'.key.'$'
            call add(list, keys[len] . vals[len])
        endif
        let len -= 1
    endw

    if len(list) > 0
        echo join(sort(list), "\n")
    else
        echo 'assistant.MISS : Can not find the information on "'.key.'"'
    endif
endf

autocmd BufEnter,BufRead * :call ASetCompFunc()
autocmd Filetype * :call ASetCompFunc()
" ================================== }}} Main ==================================
" vim:ft=vim:ff=unix:tabstop=4:shiftwidth=4:softtabstop=4:expandtab
" End of file : assistant.vim
