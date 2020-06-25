" Vim global plugin for detect tab/space indent in file
" Last Change: 2019-07-02
" Maintainer: Colin Cheng <zbinlin@outlook.com>
" License: MIT

if exists("g:loaded_indent_detector")
    finish
endif
let g:loaded_indent_detector = 1

function! s:MaxCounting(lst) abort
    let counting = {}
    for item in a:lst
        let counting[item] = get(counting, item, 1) + 1
    endfor
    let result = 0
    let maximum = 0
    for [key, value] in items(counting)
        if value > maximum
            let maximum = value
            let result = key
        endif
    endfor
    return result
endfunction

function! s:CountChar(line, char) abort
    let cnt = 0
    let len = strlen(a:line)
    let idx = 0
    while idx < len
        let ch = a:line[idx]
        if ch == a:char
            let cnt += 1
        else
            break
        endif
        let idx += 1
    endwhile
    return cnt
endfunction

let s:TAB_INDENT = 'TAB_INDENT'
let s:SPACE_INDENT = 'SPACE_INDENT'
let s:NOT_INDENT = 'NOT_INDENT'
let s:UNKNOWN_INDENT = 'UNKNOWN_INDENT'

let s:TAB = "\t"
let s:SPACE = ' '
let s:EMPTY = ''

function! s:DetectIndent() abort
    let last = line("$")
    let rows = winheight(0)
    if rows == -1
        let rows = last
    endif

    let prev_indent = s:NOT_INDENT
    let tab_score = 0
    let space_score = 0
    let score_threshold = min([max([2, rows / 2]), 8])
    let spaces = []
    let line_threshold = 1024

    let idx = 0
    let max_lines = min([line_threshold, last])
    while idx < max_lines
        let lines = getline(idx, idx + rows)
        let idx += rows

        for line in lines
            let ch = line[0]
            if prev_indent == s:NOT_INDENT
                if ch == s:TAB
                    let cnt = s:CountChar(line, ch)
                    if cnt == 1
                        let prev_indent = s:TAB_INDENT
                        let tab_score += 1
                    else
                        let prev_indent = s:UNKNOWN_INDENT
                    endif
                elseif ch == s:SPACE
                    let cnt = s:CountChar(line, ch)
                    if cnt == 2 || cnt == 4 || cnt == 8
                        let prev_indent = s:SPACE_INDENT
                        let space_score += 1
                        call add(spaces, cnt)
                    else
                        let prev_indent = s:UNKNOWN_INDENT
                    endif
                else
                    let prev_indent = s:NOT_INDENT
                endif
            elseif prev_indent == s:TAB_INDENT
                if ch == s:TAB
                    let tab_score += 1
                elseif ch == s:SPACE
                    let prev_indent = s:UNKNOWN_INDENT
                elseif ch == s:EMPTY
                    " ignore
                else
                    let prev_indent = s:NOT_INDENT
                endif
            elseif prev_indent == s:SPACE_INDENT
                if ch == s:TAB
                    let prev_indent = s:UNKNOWN_INDENT
                elseif ch == s:SPACE
                    let space_score += 1
                elseif ch == s:EMPTY
                    " ignore
                else
                    let prev_indent = s:NOT_INDENT
                endif
            elseif prev_indent == s:UNKNOWN_INDENT
                if ch == s:TAB
                    " ignore
                elseif ch == s:SPACE
                    " ignore
                else
                    let prev_indent = s:NOT_INDENT
                endif
            endif
        endfor

        if abs(space_score - tab_score) > score_threshold
            if space_score > tab_score
                return s:MaxCounting(spaces)
            else
                return -1
            endif
        endif
    endwhile

    if space_score == tab_score
        if space_score == 0
            return 0
        else
            let space = s:MaxCounting(spaces)
            if count(spaces, space) > tab_score
                return space
            else
                return -1
            endif
        endif
    elseif space_score > tab_score
        return s:MaxCounting(spaces)
    else
        return -1
    endif
endfunction

function! s:CheckModeline() abort
    return execute("verbose setl tabstop") =~ "from modeline line"
endfunction

function! s:AutoSetExpandTab() abort
    if s:CheckModeline()
        "echom "[indent-detector]: uses modeline options."
        return
    endif

    let val = s:DetectIndent()
    if val == 0
        "echom "[indent-detector]: undetected tab or space."
        " Nothing to do
    elseif val == -1
        "echom "[indent-detector]: uses tab indent."
        setlocal noexpandtab
    else
        "echom "[indent-detector]: set expandtab and tabstop=" . val
        setlocal expandtab
        setlocal shiftwidth=0
        execute("setlocal tabstop=" . val)
    endif
endfunction

autocmd BufReadPost * call <SID>AutoSetExpandTab()
