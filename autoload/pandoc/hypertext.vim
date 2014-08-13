" vim: set fdm=marker et ts=4 sw=4 sts=4:

function! pandoc#hypertext#Init()
    if !exists("g:pandoc#hypertext#open_editable_alternates")
        let g:pandoc#hypertext#open_editable_alternates = 1
    endif
    if !exists("g:pandoc#hypertext#open_cmd")
        let g:pandoc#hypertext#open_cmd = "botright vsplit"
    endif
    if !exists("g:pandoc#hypertext#preferred_alternate")
        let g:pandoc#hypertext#preferred_alternate = "md"
    endif
    noremap <silent> <buffer> <C-o>l :call pandoc#hypertext#OpenLocal()<cr>
    noremap <silent> <buffer> <C-o>s :call pandoc#hypertext#OpenSystem()<cr>
    noremap <silent> <buffer> <C-o>i :call pandoc#hypertext#GotoID()<cr>
endfunction

function! s:IsEditable(path)
    let exts = []
    for type_exts in values(g:pandoc_extensions_table)
        for ext in type_exts
            call add(exts, fnamemodify("*.".ext, ":e"))
        endfor
    endfor
    if index(exts, fnamemodify(a:path, ":e")) > -1
        return 1
    endif
    return 0
endfunction

function! s:SortAlternates(a, b)
    let ext = fnamemodify(a:a, ":e")
    if ext == g:pandoc#hypertext#preferred_alternate
        return 1
    endif
    return 0
endfunction

function! s:FindAlternates(path)
    let candidates = sort(glob(fnamemodify(a:path, ":r").".*", 0, 1), "s:SortAlternates")
    if candidates != []
        return filter(filter(candidates, 's:IsEditable(v:val)'), 'v:val != a:path')
    endif
    return []
endfunction

function! pandoc#hypertext#OpenLocal()
    let addr = expand("<cfile>")
    if g:pandoc#hypertext#open_editable_alternates == 1
        let ext = fnamemodify(addr, ":e")
        if ext =~ '\(pdf\|htm\|odt\|doc\)'
            let alt_addrs = s:FindAlternates(addr)
            if alt_addrs != []
                let addr = alt_addrs[0]
            endif
        endif
    endif
    if glob(addr) != ''
        exe g:pandoc#hypertext#open_cmd. " ".addr
    endif
endfunction

function! pandoc#hypertext#OpenSystem()
    let addr = expand("<cfile>")
    if has("unix") && executable("xdg-open")
        call system("xdg-open ". addr)
    elseif has("win32") || has("win64")
        call system('cmd /c "start '. addr .'"')
    elseif has("macunix")
        call system('open '. addr)
    endif
endfunction

function! pandoc#hypertext#GotoID()
    if synIDattr(synID(line('.'), col('.'), 0), 'name') != 'pandocHeaderID'
        let id = expand("<cfile>")
        let cur_lnum = line('.')
        let q_lnum = search(id.'-\@!', 'nc') "add -\@! so we don't move to position 'id' is a substring of the actual id
        if q_lnum != cur_lnum && q_lnum > 0
            call search(id.'-\@!')
            normal 0
        else
            let title_regex = '#*\s*'.substitute(substitute(id, '#', '', ''), '-', '\\s', 'g')
            let auto_q_lnum = search(title_regex.'-\@!', 'nc')
            if q_lnum > 0
                call search(title_regex.'-\@!')
                normal 0
            endif
        endif
    endif
endfunction