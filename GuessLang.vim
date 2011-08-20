"===========================================================================
" File: 	GuessLang.vim
" Author: Arno Renevier <arno@renevier.net>
"
" Purpose: 
"   Guess the language of an email to set the correct spelllang automatically.
"   It works by feeding the content to aspell once for each possible language,
"   and choosing the one triggering the smallest number of mispelled words
"
" Installation:	
"   - Drop this file into ~/.vim/ftplugin/mail/ directory (create it if needed).
"   - Make sure filetype plugins are enabled ("filetype plugin on" in your
"   .vimrc)
"   - Define in your .vimrc a variable "g:spell_choices" containing a comma
"   separated list of languages to choose from. Otherwise, a default value of
"   "fr,en" is assumed. If two languages have equal probability, the first one
"   in the list is choosen.
"
" Thanks:	Clochix for his idea on the general algorithm
"===========================================================================

" strip email headers except subject content; otherwise, guess would be biased
" toward english
function! s:getContent()
    " -1: before headers
    " 0: inside headers
    " 1: headers passed
    let l:headerstatus = -1
    let l:result = []
    for l:line in getline(1, '$')
        if l:headerstatus == -1
            if match(l:line, '^From:') == 0
                " the are some headers to edit
                let l:headerstatus = 0
            else
                " the are no headers to edit
                let l:headerstatus = 1
            endif
        endif

        if l:headerstatus == 0 
            if len(l:line) == 0
                " end of headers
                let l:headerstatus = 1
            elseif match(l:line, '^Subject:') == 0
                let l:oldignorecase = &ignorecase
                set ignorecase
                let l:result = add(l:result, substitute(l:line, '^Subject:\s*\(Re:\s*\)\?', "", ""))
                if ! l:oldignorecase
                    set noignorecase
                endif
            endif
        else
            let l:result = add(l:result, l:line)
        endif

    endfor
    return join(l:result, "\n")
endfunction

function! s:trimstr(str)
    let l:res = a:str
    let l:res = substitute(l:res, '^\s*', "", "")
    let l:res = substitute(l:res, '\s*$', "", "")
    return l:res
endfunction

function! s:betterLanguage(choices)
    let l:content = s:getContent()

    if len(l:content) == 0 
        " no content; default to french
        return s:trimstr(split(a:choices, ",")[0])
    endif

    let l:available = split(system("aspell dicts"))

    " for each language, get number of misspelled words according to aspell.
    " The langue with the least misspelled words is considered the spell
    " language
    let l:lang = ""
    let l:missmin = -1
    for l:guess in split(a:choices, ",")
        let l:guess = s:trimstr(l:guess)
        if index(l:available, l:guess) == -1 " lang is  not available in aspell dictionary
            call s:warning("language " . l:guess . " is not recognized by aspell")
            continue
        endif

        let l:misspelled = system("cat | aspell -l " . l:guess . " list | sort -u", l:content)
        let l:misslen = len(split(l:misspelled))
        if l:misslen == 0
            let l:lang = l:guess
            break
        elseif l:missmin == -1 || l:misslen < l:missmin
            let l:missmin = l:misslen
            let l:lang = l:guess
        endif
    endfor

    return l:lang
endfunction

function! s:warning(message)
    echohl WarningMsg 
        echoe a:message
    echohl None
endfunction

function! s:guessSpellLang()
    if ! executable('aspell')
        call s:warning("aspell is not installed")
        return
    endif

    if exists("g:spell_choices")
        let l:choices = g:spell_choices
    else
        let l:choices = "fr,en"
    endif

    let l:lang = s:betterLanguage(l:choices)
    set spell
    if len(l:lang)
        exe "set spelllang=" . l:lang
    endif
endfunction

call s:guessSpellLang()
