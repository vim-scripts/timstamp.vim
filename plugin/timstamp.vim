" Vim global plugin for automated time stamping
" Last Change: 2002 Aug 12
" Timestamp: <timstamp.vim Mon 2002/08/12 18:22:09 guivho BTM4BZ>
" Maintainer: Guido Van Hoecke <Guido@VanHoecke.org>
" Description: Cfr separate 'timstamp.txt' help file
" Version: 0.92
" History: 
    " 0.92 now uses the line("$") function to test for short files
	" and limits the modifications to the specified nr of lines
	" rather than that number plus one extra line
	" (Thanks to Piet Delport)
    " 0.91 now preserves cursor location, is silent! about language
	 " setting, and does no longer choke on short files 
	 " (Thanks to Rimon Barr)

" provide load control
    if exists("loaded_timstamp")
	finish
    endif
    let loaded_timstamp = 1

function! s:getValue(deflt, globl, ...)
    " helper function to define script variables by using
    " first any specified global value, any non zero value from
    " the optional parameters, and finally if all these fail to
    " provide a value, by using the default value
    if exists(a:globl)
	let work = "let value = " . a:globl
	exe work
	return value
    endif
    let indx = 1
    while indx <= a:0
	let work = "let value = a:" . indx
	exe work
	if value != ""
	    return value
	endif
	let indx = indx + 1
    endwhile
    return a:deflt 
endfunction

" The two default timestamp control specs
let s:timstamp_1 = s:getValue( '\( Last \?\(changed\?\|modified\):\).*$'
	\ . '!\1 %Y %b %d', "g:timstamp_1")
let s:timstamp_2 = s:getValue('\( Time[- ]\?stamp:\).*$'
	\ . '!\1 <#f %a %Y/%m/%d %H:%M:%S #u #h>', "g:timstamp_2")

" Control variables that could be overruled by the user: 
let s:automask   = s:getValue("*", "g:timstamp_automask")
let s:hostname   = s:getValue(substitute(hostname(), ".* ", "", ""), 
			\ "g:timstamp_hostname", $HOSTNAME)
let s:Hostname   = s:getValue(hostname(), "g:timstamp_hostname", $HOSTNAME)
let s:ignorecase = s:getValue("i", "g:timstamp_ignorecase")
let s:language   = s:getValue("en", "g:timstamp_language")
let s:modelines  = s:getValue(&modelines, "g:timstamp_modelines")
let s:userid     = s:getValue($LOGNAME, "g:timstamp_userid")
let s:username   = s:getValue($USERNAME, "g:timstamp_username")

function! s:filename()
    " Function returns the filename of the current buffer
    " without any of the path components
    return substitute(bufname(""), ".*[\/]", "", "")
endfunction

function! s:stamper(mask)
    " does the actual timestamp substitution for each of the 
    " specified timstamp_n masks
    let mask = a:mask
    let mask = strftime(mask)
    let mask = substitute(mask, "#f", s:filename(), "g")
    let mask = substitute(mask, "#h", s:hostname, "g")
    let mask = substitute(mask, "#H", s:Hostname, "g")
    let mask = substitute(mask, "#n", s:username, "g")
    let mask = substitute(mask, "#u", s:userid, "g")
    let mask = 's!' . mask . '!e' . s:ignorecase
    exe 'silent! ' . s:range1 . mask
    if s:range2 != ""
	exe 'silent! ' . s:range2 . mask
    endif
endfunction

function! s:timeStamper()
    " loops over the specified timstamp_n masks and calls upon
    " s:stamper to process each of them
    let language =  v:lc_time " preserve it
    exe ":normal msHmt"
    exe ":silent! language time " . s:language
    if s:modelines == '$'
	s:modelines = line('$')
    endif
    if line('$') > s:modelines
	let s:range1 = '1,' . s:modelines
	if line('$') >= ( 2 * s:modelines )
	    let s:range2 = '$+1-' . s:modelines . ',$'
	else
	    let s:range2 = s:modelines . '+1,$'
	endif
    else
	let s:range1 = '%'
	let s:range2 = ''
    endif
    let indx = 1
    while exists("s:timstamp_" . indx)
	let work = "let mask = s:timstamp_" . indx
	exe work
	if mask == ""
	    return
	endif
	call s:stamper(mask)
	let indx = indx + 1
    endwhile
    " restore preserved language
    exe ":silent! language time " . language
    exe ":normal 'tzt`s"
endfunction
	
let s:autocomm   = "autocmd BufWrite " . s:automask . " :call s:timeStamper()"
augroup Timestamp
    " this autocommand triggers the update of the requested timestamps
    au!
    exe s:autocomm
augroup END

