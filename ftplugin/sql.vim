" ------------------------------------
" Vim for Vertica SQL File Type Plugin
" ------------------------------------

" Common settings:
setlocal expandtab
setlocal tabstop=4

" Status line:
let &statusline=g:basestatus
setlocal statusline+=%y\ F3\=SQLfmt\ F4\=SQLrun\ F5\=Explain\ F6\=GExplain

" Configurable paramaters:
:let vfv_pfx="-- out "
:let vfv_pfe="-- exp "
:let vfv_tmp="~/._vfv.sql"
:let vfv_exp="EXPLAIN "
:let vfv_sql="vsql -X -i -f " . vfv_tmp . " 2>&1"
:let vfv_fmt="sqlformat -k upper -s -r --indent_width 4 --indent_columns -"
:let vfv_sed="| sed 's@^@" . vfv_pfx . "@'"
:let vfv_see="| sed -n '/^ Access Path:$/,/^ $/ s/^/" . vfv_pfe . "/p' | sed '$d'"
:let b:uname = system("uname")
:if b:uname == "Linux\n"
:    let vfv_dot="| sed -n '/^ digraph /,/^ }$/p' | dot -Tpdf > ._vfv_explain.pdf && xdg-open ._vfv_explain.pdf"
:elseif b:uname == "Darwin\n"
:    let vfv_dot="| sed -n '/^ digraph /,/^ }$/p' | dot -Tpdf > ._vfv_explain.pdf && open ._vfv_explain.pdf"
:endif
":let vfv_see="| sed -n 

" Fold reated settings:
autocmd BufWinLeave *.* mkview
autocmd BufWinEnter *.* silent loadview 
setlocal foldmethod=expr
":set foldexpr=getline(v:lnum)=~vfv_pfe\|vfv_pfx
let &foldexpr='getline(v:lnum)=~''-- out\|exp '''
nnoremap <Tab> za

" Highlights for sqlOutput and sqlExlpain
syn match sqlOutput  "-- out.*$"
syn match sqlExplain "-- exp.*$"
highlight sqlOutput ctermfg=18 guifg=#000087
highlight sqlExplain ctermfg=89 guifg=#870087

" Clear mappings:
:silent! unmap <buffer> <F3>
:silent! unmap <buffer> <F4>
:silent! unmap <buffer> <F5>
:silent! unmap <buffer> <F6>

" CLI mappings:
:map <silent> <buffer> <F3>	:<C-U>execute '''<,''>!' . vfv_fmt<CR>
:map <silent> <buffer> <F4>	:<C-U>execute '''<,''>w!' . vfv_tmp<CR><bar> :<C-U>execute '''>:r!' . vfv_sql . vfv_sed <CR> <bar> zo
:map <silent> <buffer> <F5> :<C-U>call writefile([vfv_exp], expand(vfv_tmp),"")<CR><bar> :<C-U>execute '''<,''>w! >>' . vfv_tmp<CR><bar> :<C-U>execute '''>:r!' . vfv_sql . vfv_see <CR> <bar> zo
:map <silent> <buffer> <F6> :<C-U>call writefile([vfv_exp], expand(vfv_tmp),"")<CR><bar> :<C-U>execute '''<,''>w! >>' . vfv_tmp<CR><bar> :<C-U>execute '''>:r!' . vfv_sql . vfv_dot <CR>

" GUI mappings:
vnoremenu 1.16 PopUp.SQL\ format :<C-U>execute '''<,''>!' . vfv_fmt<CR>
vnoremenu 1.17 PopUp.SQL\ run :<C-U>execute '''<,''>w!' . vfv_tmp<CR><bar> :<C-U>execute '''>:r!' . vfv_sql . vfv_sed <CR> <bar> zo
vnoremenu 1.18 PopUp.SQL\ explain\ text :<C-U>call writefile([vfv_exp], expand(vfv_tmp),"")<CR><bar> :<C-U>execute '''<,''>w! >>' . vfv_tmp<CR><bar> :<C-U>execute '''>:r!' . vfv_sql . vfv_see <CR> <bar> zo
vnoremenu 1.19 PopUp.SQL\ explain\ graph :<C-U>call writefile([vfv_exp], expand(vfv_tmp),"")<CR><bar> :<C-U>execute '''<,''>w! >>' . vfv_tmp<CR><bar> :<C-U>execute '''>:r!' . vfv_sql . vfv_dot . '&'<CR>
an 1.19 PopUp.-SEP5-			<Nop>
