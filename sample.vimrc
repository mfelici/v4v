"------------------------------------------------------------------------
" Common options
"------------------------------------------------------------------------
set autoindent								" indent style
set smartindent								" indent style
set t_Co=256								" setting 256 colors
set textwidth=76							" max char in a line
set showcmd									" show initial command chars
set showmode								" show editing mode
set showmatch								" show parenthesis matches
set ruler									" show row/column
set rulerformat=%40([%{&ff}]\ [%03.3b\ 0x%02.2B]\ %l/%L,%c%)
set tabstop=4								" tab = 4 spaces
set shiftwidth=4							" tab = 4 spaces
set ignorecase								" during searches
set smartcase								" ... but if i write Uppercase...
set cpoptions=aABceFs$
set hlsearch								" search highlighting
set modeline modelines=5					" look the first/last 5 rows
set nocompatible							" no too much "vi" compatible
set comments+=fb:*							" '*' as a bullet list
set scrolloff=2								" always keep 2 lines visible
set runtimepath=$HOME/.vim,$VIMRUNTIME		" needed for win (def $HOME/vimfiles)
set pastetoggle=<F12>						" switch off autoindent (copying indented text)
set encoding=utf-8
set nu										" numbered lines
set paste									" insert paste
set viminfo='50,<1000,n~/.vim/viminfo		" viminfo location
syntax on
filetype plugin on                          " Switch filetype plugin on
let g:sql_type_default = 'sqlvertica'		" Change default SQL Dialect from Oracle to Vertica

"------------------------------------------------------------------------
" GUI options
"------------------------------------------------------------------------
if has ("gui_running")
	set lines=52
	set co=96
	set guifont=Menlo:h14
	menu 20.351 Edit.Copy\ to\ HTML :'<,'>Copy2HTML<CR>
	menu 20.352 Edit.Copy\ to\ RTF :'<,'>CopyRTF<CR>
	vnoremenu 1.31 PopUp.Copy\ to\ HTML :'<,'>Copy2HTML<CR>
	vnoremenu 1.32 PopUp.Copy\ to\ RTF :'<,'>CopyRTF<CR>
endif

"------------------------------------------------------------------------
" Cursor Line
"------------------------------------------------------------------------
hi CursorLine cterm=bold ctermbg=249 gui=bold guibg=lightgray
hi Visual ctermbg=159 guibg=PaleTurquoise1
hi Search ctermfg=0 ctermbg=190 guibg=Yellow2
hi Normal guibg=lightyellow
set cursorline
:let macvim_skip_colorscheme=1

"------------------------------------------------------------------------
" Status Line (Left Side)
"------------------------------------------------------------------------
set statusline=%f                               " file name
set statusline+=[%{strlen(&fenc)?&fenc:'none'}, " file encoding
set statusline+=%{&ff}]                         " file format
set statusline+=%m                              " modified flag
set statusline+=%r                              " read only flag
set statusline+=\ %=                            " align left
set statusline+=Line:%4l/%5L[%p%%]              " line X of Y [% of file]
set statusline+=\ Col:%03c                      " current column
set statusline+=\ ASCII:[%03b][0x%02B]\         " ASCII DEC/HEX under cursor
let basestatus=&statusline                      " save base status line
set laststatus=2                                " Always display status
"hi statusline guibg=DodgerBlue2 ctermfg=15 guifg=White ctermbg=27
hi StatusLine ctermfg=27 ctermbg=15 guibg=White guifg=DodgerBlue2

"------------------------------------------------------------------------
" Mapping keys
"------------------------------------------------------------------------
" CTRL-Tab => Move to the next split
noremap <C-Tab> <C-W>w
inoremap <C-Tab> <C-O><C-W>wa
cnoremap <C-Tab> <C-C><C-W>w
onoremap <C-Tab> <C-C><C-W>w

" BS to as :nohlsearch
nmap <silent> <BS> :nohlsearch<CR>

"------------------------------------------------------------------------
" Functions
"------------------------------------------------------------------------
" open the file at the same line number it was closed last time
if has("autocmd")
	au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$")
		\| exe "normal! g'\"" | endif
endif

"Copy_to_HTML
function! CopyToHTML(line1, line2)
	let g:html_number_lines=0
	let g:html_ignore_folding=1
	let g:html_dynamic_folds=0
	let g:html_use_css=0
    let g:html_font="Courier"
	exec a:line1.','.a:line2.'TOhtml'
	%g/<body/normal k$dgg
	%s/<body\s*\(bgcolor="[^"]*"\)\s*text=\("[^"]*"\).*$/<table \1 width="95%" cellPadding=0><tr><td><font color=\2>/
	%s#</body>\(.\|\n\)*</html>#\='</font></td></tr></table>'#i
    w !pbcopy
	q!
endfunction
command! -range=% Copy2HTML :silent call CopyToHTML(<line1>,<line2>)

fun! ShowFuncName()
	let lnum = line(".")
	let col = col(".")
	echohl ModeMsg
	echo getline(search("^[^ \t#/]\\{2}.*[^:]\s*$", 'bW'))
	echohl None
	call search("\\%" . lnum . "l" . "\\%" . col . "c")
endfun
map f :call ShowFuncName() <CR>
