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
"     .vimrc)
"   - Define in your .vimrc a variable "g:spell_method" containing the spell
"     check programm to use. Currently, only "aspell" (default) and "hunspell"
"     are supported
"   - Define in your .vimrc a variable "g:spell_choices" containing a comma
"     separated list of languages to choose from. Otherwise, a default value of
"     "fr,en" is assumed. If two languages have equal probability, the first one
"     in the list is choosen.
"
" Thanks:	Clochix for his idea on the general algorithm
"===========================================================================

" strip email headers except subject content; otherwise, guess would be biased
" toward english
function s:stripHeaders()
    let l:headersend = 0
    let l:result = []
    for l:line in getline(1, '$')
        if len(l:line) == 0
            let l:headersend = 1
        elseif l:headersend
            let l:result = add(l:result, l:line)
        elseif match(l:line, '^Subject:') == 0
            let l:oldignorecase = &ignorecase
            set ignorecase
            let l:result = add(l:result, substitute(l:line, '^Subject:\s*\(Re:\s*\)\?', '', ''))
            if ! l:oldignorecase
                set noignorecase
            endif
        endif
    endfor
    return join(l:result, '\n')
endfunction

function s:trim(str)
    let l:res = a:str
    let l:res = substitute(l:res, '^\s*', '', '')
    let l:res = substitute(l:res, '\s*$', '', '')
    return l:res
endfunction

function! s:betterLanguage(method, choices)
    let l:content = s:stripHeaders()

    if len(l:content) == 0 
        " no content; default to french
        return trim(split(a:choices, ',')[0])
    endif

    if a:method == 'aspell'
        let l:available = split(system('aspell dicts'))
    elseif a:method == 'hunspell'
        let l:available = split(system("echo | hunspell -D 2>&1 | grep -v : | grep / | sed 's/\\/.*\\///'"))
    endif

    " for each language, get number of misspelled words according to aspell.
    " The langue with the least misspelled words is considered the spell
    " language
    let l:lang = ''
    let l:missmin = -1
    for l:guess in split(a:choices, ',')
        let l:guess = s:trim(l:guess)
        if index(l:available, l:guess) == -1 " lang is  not available in aspell dictionary
            call s:warning('language ' . l:guess . ' is not recognized by aspell')
            call s:warning('available languages ' . join(l:available, ', '))
            continue
        endif

        if a:method == 'aspell'
            let l:misspelled = system('cat | aspell -l ' . l:guess . ' list | sort -u', l:content)
        elseif a:method == 'hunspell'
            let l:misspelled = system('cat | hunspell -d ' . l:guess . ' -l | sort -u', l:content)
        endif
        let l:misslen = len(split(l:misspelled))
        if l:misslen == 0
            let l:lang = l:guess
            break
        elseif l:missmin == -1 || l:misslen < l:missmin
            let l:missmin = l:misslen
            let l:lang = l:guess
        endif
    endfor

    return strpart(l:lang, 0, 2)
endfunction

function s:warning(message)
    echohl WarningMsg 
        echoe a:message
    echohl None
endfunction

function s:guessSpellLang()
    if exists('g:spell_method')
        let l:method = g:spell_method
    else
        let l:method = 'aspell'
    endif
    if l:method != 'aspell' && l:method != 'hunspell'
        call s:warning('Unknown method ' . l:method)
        return
    endif
    if l:method == 'aspell' && ! executable('aspell')
        call s:warning('aspell is not installed')
        return
    endif
    if l:method == 'hunspell' && ! executable('hunspell')
        call s:warning('hunspell is not installed')
        return
    endif

    if exists('g:spell_choices')
        let l:choices = g:spell_choices
    else
        let l:choices = 'fr,en'
    endif

    let l:lang = s:betterLanguage(l:method, l:choices)
    set spell
    if len(l:lang)
        echo 'Detected language' l:lang
        exe 'set spelllang=' . l:lang
    endif
endfunction

call s:guessSpellLang()
