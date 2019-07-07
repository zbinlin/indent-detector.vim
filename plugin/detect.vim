" Vim global plugin for detect tab/space indent in file
" Last Change: 2019-07-02
" Maintainer: Colin Cheng <zbinlin@outlook.com>
" License: MIT

if exists("g:loaded_indent_detector")
    finish
endif
let g:loaded_indent_detector = 1

function MaxCounting(lst) abort
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

function CountChar(line, char) abort
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

function DetectIndent() abort
    let last = line("$")
    let rows = winheight(0)
    if rows == -1
        let rows = last
    endif

    let prev = 0
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
            if prev == 0
                if ch == '\t'
                    let cnt = CountChar(line, ch)
                    if cnt == 1
                        let prev = -1
                        let tab_score += 1
                    else
                        let prev = -2
                    endif
                elseif ch == ' '
                    let cnt = CountChar(line, ch)
                    if cnt == 2 || cnt == 4 || cnt == 8
                        let prev = 1
                        let space_score += 1
                        call add(spaces, cnt)
                    else
                        let prev = 2
                    endif
                else
                    let prev = 0
                endif
            elseif prev == -1
                if ch == '\t'
                    let tab_score += 1
                elseif ch == ' '
                    let prev = 2
                else
                    let prev = 0
                endif
            elseif prev == 1
                if ch == '\t'
                    let prev = 2
                elseif ch == ' '
                    let space_score += 1
                else
                    let prev = 0
                endif
            endif
        endfor

        if abs(space_score - tab_score) > score_threshold
            if space_score > tab_score
                return MaxCounting(spaces)
            else
                return -1
            endif
        endif
    endwhile

    if space_score == tab_score && space_score == 0
        return 0
    elseif space_score > tab_score
        return MaxCounting(spaces)
    else
        return -1
    endif
endfunction

function CheckModeline() abort
    return execute("verbose setl tabstop") =~ "from modeline line"
endfunction

function AutoSetExpandTab() abort
    if CheckModeline()
        "echom "[indent-detector]: uses modeline options."
        return
    endif

    let val = DetectIndent()
    if val == 0
        "echom "[indent-detector]: undetected tab or space."
        return
    elseif val == -1
        "echom "[indent-detector]: uses tab indent."
        return
    endif

    setlocal expandtab
    execute("setlocal tabstop=" . val)
endfunction

autocmd BufReadPost * call AutoSetExpandTab()
