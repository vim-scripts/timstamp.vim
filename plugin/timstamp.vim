" Vim global plugin for automated time stamping - v0.95
" Last Change: 2003 Feb 13
" Timestamp: <timstamp.vim Thu 2003/02/13 22:57:13  MSDOG>
" Maintainer: Guido Van Hoecke <Guido@VanHoecke.org>
" Description: Cfr separate 'timstamp.txt' help file
" License: This file is placed in the public domain.
" History: 
    " 0.95
	" 1) Replaced s:filename() by call to builtin fnamemodify()
	" 2) Added license statement
	" 3) Now processes g:timstamp_3 etc by copying them into 
	"    s:timestamp_3 at the beginning of the script
	"    (Thanks to Norihiko Murase)
	" 4) Fixed two documentation typos (Thanks to Norihiko Murase)
    " 0.94 
	" 1) Added a missing 'let' in an assignment statement.
	"    (reported by Luis Jure)
	" 2) Added additional warning in the help file about 
	"    '$' value for g:timstamp_modelines. 
	"    Cfr :h timstamp_modelines
	" 3) Corrected s:filename() to also work with dos slashes
	"    (thanks to Richard Bair)
    " 0.93 Now only presents the %token part of the spec to 
	" strftime(): this seems to provide correct results, 
	" even when using %Z to add the timezone followed by '>'
	" The helpfile has been extended with aome example specs.
	" (error and help reported/requested by Adrian Nagle)
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

" copy remaining user-specified g:timestamp_n masks
let indx = 3
while exists("g:timstamp_" . indx)
    let work = "let s:timstamp_" . indx . "= g:timstamp_" . indx
    exe work
    let indx = indx + 1
endwhile

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

function! s:stamper(mask)
    " does the actual timestamp substitution for each of the 
    " specified timstamp_n masks
    let mask = a:mask
    let idx = stridx(mask, '%')
    if idx >= 0
    	let str1 = strpart(mask, idx)
	let ridx = strridx(str1, '%')
	if ridx >= 0 
	    if ridx < strlen(str1)
		let str2 = strpart(str1, 0,  ridx + 2)
		let str3 = strpart(str1, ridx + 2)
		let str2 = strftime(str2) . str3
	    endif
	    let mask = strpart(mask, 0, idx) . str2
	endif
    endif
    let mask = substitute(mask, "#f", fnamemodify(bufname(""), ":p:t"), "g")
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
	let s:modelines = line('$')
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

