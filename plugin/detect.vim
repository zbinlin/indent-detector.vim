" Vim global plugin for detect tab/space indent in file
" Last Change: 2019-07-02
" Maintainer: Colin Cheng <zbinlin@outlook.com>
" License: MIT

if exists("g:loaded_indent_detector")
    finish
endif
let g:loaded_indent_detector = 1

function DetectIndent() abort
    let last = line("$")
    let rows = winheight(0)
    if rows == -1
        let rows = last
    endif

    let idx = 0
    let tab_score = 0
    let space_score = 0
    let space_count = -1
    let start_count = v:false
    while idx < last
        let lines = getline(idx, idx + rows)
        let idx += rows
        for line in lines
            if line[0] != '\t' && line[0] != ' '
                if tab_score > space_score
                    return -1
                elseif tab_score < space_score
                    return space_count
                endif
                let start_count = v:false
                continue
            endif
            if !start_count
                let start_count = v:true
                let tab_score = 0
                let space_score = 0
            endif

            if line[0] == '\t'
                let tab_score += 1
                let space_score -= 1
                continue
            endif

            let cnt = 0
            let len = strlen(line)
            let iidx = 0
            while iidx < len
                let ch = line[iidx]
                if ch == ' '
                    let cnt += 1
                else
                    break
                endif
                let iidx += 1
            endwhile

            if cnt % 8 == 0
                let space_count = 8
            elseif cnt % 4 == 0
                let space_count = 4
            elseif cnt % 2 == 0
                let space_count = 2
            endif

            if cnt % 2 == 0
                let space_score += 1
                let tab_score -= 1
            endif
        endfor
    endwhile

    return space_count
endfunction

function CheckModeline() abort
    return execute("verbose setl tabstop") =~ "from modeline line"
endfunction

function AutoSetExpandTab() abort
    if CheckModeline()
        echom "[indent-detector]: uses modeline options."
        return
    endif

    let val = DetectIndent()
    if val == -1
        echom "[indent-detector]: uses tab indent."
        return
    endif

    setlocal expandtab
    execute("setlocal tabstop=" . val)
endfunction

autocmd BufReadPost * call AutoSetExpandTab()
