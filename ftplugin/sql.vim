" ------------------------------------
" Vim for Vertica SQL File Type Plugin
" ------------------------------------

" Common settings:
setlocal expandtab
setlocal tabstop=4

" Status line:
let &statusline=g:basestatus
setlocal statusline+=%y\ F3\=fmt\ F4\=run\ F5\=Exp\ F6\=GExp\ F7\=env\ F8=prof\ F9=Vrun
let maplocalleader=","

" Configurable paramaters:
:let vfv_pfx="-- out "
:let vfv_pfe="-- exp "
:let vfv_tmp="~/._vfv.sql"
:let vfv_exp="EXPLAIN "
":let vfv_sql="vsql -X -i -f " . vfv_tmp . " 2>&1"
:let vfv_sql="vsql -X -i -f " . vfv_tmp . " 2>&1 | sed 's/^vsql:.*._vfv.sql:[0-9]*: //'"
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
:silent! unmap <buffer> <F7>
:silent! unmap <buffer> <F8>
:silent! unmap <buffer> <F9>
:silent! unmap <buffer> <F10>
:silent! unmap <buffer> <F12>

" Function Key mappings:
:map <silent> <buffer> <F3>	:<C-U>execute '''<,''>!' . vfv_fmt<CR>
:map <silent> <buffer> <F4>	:<C-U>execute '''<,''>w!' . vfv_tmp<CR>
    \:<C-U>execute '''>:r!' . vfv_sql . vfv_sed <CR>
    \zo
:map <silent> <buffer> <F5> :<C-U>call writefile([vfv_exp], expand(vfv_tmp),"")<CR>
    \:<C-U>execute '''<,''>w! >>' . vfv_tmp<CR>
    \:<C-U>execute '''>:r!' . vfv_sql . vfv_see <CR>
    \zo
:map <silent> <buffer> <F6> :<C-U>call writefile([vfv_exp], expand(vfv_tmp),"")<CR>
    \:<C-U>execute '''<,''>w! >>' . vfv_tmp<CR>
    \:<C-U>execute '''>:r!' . vfv_sql . vfv_dot <CR>
:map <silent> <F7> :echon 
    \"$VSQL_USER='" $VSQL_USER
    \"' $VSQL_HOST='" $VSQL_HOST
    \"' $VSQL_DATABASE='" $VSQL_DATABASE
    \"' $VSQL_PASSWORD='" $VSQL_PASSWORD "'"<CR>
noremap <silent> <localleader>D viW
    \:<C-U>let vfv_tab=getline("'<")[getpos("'<")[2]-1:getpos("'>")[2]]<CR>
    \:let vfv_ddl='vsql -Xtnqc "SELECT EXPORT_OBJECTS('''',''' . vfv_tab . ''')"'<CR>
    \:let vfv_tab .= '.sql'<CR>
    \:execute 'tabnew' vfv_tab<CR>
    \:execute 'r!' . vfv_ddl<CR>
    \gg
noremap <silent> <localleader>I viW
    \:<C-U>let vfv_tab=getline("'<")[getpos("'<")[2]-1:getpos("'>")[2]]<CR>
    \:let vfv_cmd='~/.vim/vertica/vfv_info.sh ' . vfv_tab<CR>
    \:let vfv_tab .= '.info'<CR>
    \:execute 'tabnew' vfv_tab<CR>
    \:execute 'r!' . vfv_cmd<CR>
    \gg
noremap <silent> <F8> :<C-U>execute '''<,''>w!' . vfv_tmp<CR>
    \:tabnew<CR>
    \:execute 'r! ~/.vim/vertica/vfv_prof.sh'<CR>
    \gg
noremap <silent> <F9> y:<C-U>@"<CR>
noremap <silent> <F10> :tabnew running_jobs<CR>
    \:execute 'r! vsql -X -qf ~/.vim/vertica/vfv_jobs.sql'<CR>
    \gg
noremap <silent> <F12> :tabnew host_resources<CR>
    \:execute 'r! vsql -X -x -qf ~/.vim/vertica/vfv_host.sql'<CR>
    \gg
noremap <silent> <localleader>s viW
    \:<C-U>let vfv_tab=getline("'<")[getpos("'<")[2]-1:getpos("'>")[2]-1]<CR>
    \:let vfv_cmd='vsql -X -qf ~/.vim/vertica/vfv_select.sql -v arg=' . vfv_tab<CR>
    \:let vfv_tab .= '_select.sql'<CR>
    \:execute 'tabnew' vfv_tab<CR>
    \:execute 'r!' . vfv_cmd<CR>
    \gg
noremap <silent> <localleader>.s viW
    \:<C-U>let vfv_tab=getline("'<")[getpos("'<")[2]-1:getpos("'>")[2]-1]<CR>
    \:let vfv_cmd='vsql -X -qf ~/.vim/vertica/vfv_select.sql -v arg=' . vfv_tab<CR>
    \:let vfv_tab .= '_select.sql'<CR>
    \:execute 'r!' . vfv_cmd<CR>
noremap <silent> <localleader>w viW
    \:<C-U>let vfv_tab=getline("'<")[getpos("'<")[2]-1:getpos("'>")[2]-1]<CR>
    \:let vfv_cmd='vsql -X -qf ~/.vim/vertica/vfv_where.sql -v arg=' . vfv_tab<CR>
    \:let vfv_tab .= '_where.sql'<CR>
    \:execute 'tabnew' vfv_tab<CR>
    \:execute 'r!' . vfv_cmd<CR>
    \gg
noremap <silent> <localleader>.w viW
    \:<C-U>let vfv_tab=getline("'<")[getpos("'<")[2]-1:getpos("'>")[2]-1]<CR>
    \:let vfv_cmd='vsql -X -qf ~/.vim/vertica/vfv_where.sql -v arg=' . vfv_tab<CR>
    \:let vfv_tab .= '_where.sql'<CR>
    \:execute 'r!' . vfv_cmd<CR>
noremap <silent> <localleader>i viW
    \:<C-U>let vfv_tab=getline("'<")[getpos("'<")[2]-1:getpos("'>")[2]-1]<CR>
    \:let vfv_cmd='vsql -X -qf ~/.vim/vertica/vfv_insert.sql -v arg=' . vfv_tab<CR>
    \:let vfv_tab .= '_inserti.sql'<CR>
    \:execute 'tabnew' vfv_tab<CR>
    \:execute 'r!' . vfv_cmd<CR>
    \gg
noremap <silent> <localleader>.i viW
    \:<C-U>let vfv_tab=getline("'<")[getpos("'<")[2]-1:getpos("'>")[2]-1]<CR>
    \:let vfv_cmd='vsql -X -qf ~/.vim/vertica/vfv_insert.sql -v arg=' . vfv_tab<CR>
    \:let vfv_tab .= '_inserti.sql'<CR>
    \:execute 'r!' . vfv_cmd<CR>
noremap <silent> <localleader>u viW
    \:<C-U>let vfv_tab=getline("'<")[getpos("'<")[2]-1:getpos("'>")[2]-1]<CR>
    \:let vfv_cmd='vsql -X -qf ~/.vim/vertica/vfv_update.sql -v arg=' . vfv_tab<CR>
    \:let vfv_tab .= '_update.sql'<CR>
    \:execute 'tabnew' vfv_tab<CR>
    \:execute 'r!' . vfv_cmd<CR>
    \gg
noremap <silent> <localleader>.u viW
    \:<C-U>let vfv_tab=getline("'<")[getpos("'<")[2]-1:getpos("'>")[2]-1]<CR>
    \:let vfv_cmd='vsql -X -qf ~/.vim/vertica/vfv_update.sql -v arg=' . vfv_tab<CR>
    \:let vfv_tab .= '_update.sql'<CR>
    \:execute 'r!' . vfv_cmd<CR>
noremap <silent> <localleader>m viW
    \:<C-U>let vfv_tab=getline("'<")[getpos("'<")[2]-1:getpos("'>")[2]-1]<CR>
    \:let vfv_cmd='vsql -X -qf ~/.vim/vertica/vfv_merge.sql -v arg=' . vfv_tab<CR>
    \:let vfv_tab .= '_merge.sql'<CR>
    \:execute 'tabnew' vfv_tab<CR>
    \:execute 'r!' . vfv_cmd<CR>
    \gg
noremap <silent> <localleader>.m viW
    \:<C-U>let vfv_tab=getline("'<")[getpos("'<")[2]-1:getpos("'>")[2]-1]<CR>
    \:let vfv_cmd='vsql -X -qf ~/.vim/vertica/vfv_merge.sql -v arg=' . vfv_tab<CR>
    \:let vfv_tab .= '_merge.sql'<CR>
    \:execute 'r!' . vfv_cmd<CR>
noremap <silent> <localleader>c viW
    \:<C-U>let vfv_tab=getline("'<")[getpos("'<")[2]-1:getpos("'>")[2]-1]<CR>
    \:let vfv_cmd='vsql -X -qf ~/.vim/vertica/vfv_copy.sql -v arg=' . vfv_tab<CR>
    \:let vfv_tab .= '_copy.sql'<CR>
    \:execute 'tabnew' vfv_tab<CR>
    \:execute 'r!' . vfv_cmd<CR>
    \gg
noremap <silent> <localleader>.c viW
    \:<C-U>let vfv_tab=getline("'<")[getpos("'<")[2]-1:getpos("'>")[2]-1]<CR>
    \:let vfv_cmd='vsql -X -qf ~/.vim/vertica/vfv_copy.sql -v arg=' . vfv_tab<CR>
    \:let vfv_tab .= '_copy.sql'<CR>
    \:execute 'r!' . vfv_cmd<CR>
noremap <silent> <localleader>h :<C-U>!cat ~/.vim/vertica/vfv_help.txt<CR>

" GUI mappings:
vnoremenu 1.16 PopUp.SQL\ format :<C-U>execute '''<,''>!' . vfv_fmt<CR>
vnoremenu 1.16 PopUp.SQL\ run :<C-U>execute '''<,''>w!' . vfv_tmp<CR>
	\:<C-U>execute '''>:r!' . vfv_sql . vfv_sed <CR>
	\zo
vnoremenu 1.17 PopUp.SQL\ explain\ text :<C-U>call writefile([vfv_exp], expand(vfv_tmp),"")<CR>
	\:<C-U>execute '''<,''>w! >>' . vfv_tmp<CR>
	\:<C-U>execute '''>:r!' . vfv_sql . vfv_see <CR>
	\zo
vnoremenu 1.17 PopUp.SQL\ explain\ graph :<C-U>call writefile([vfv_exp], expand(vfv_tmp),"")<CR>
	\:<C-U>execute '''<,''>w! >>' . vfv_tmp<CR>
	\:<C-U>execute '''>:r!' . vfv_sql . vfv_dot . '&'<CR>
noremenu 1.18 PopUp.SQL\ get\ DDL viW
    \:<C-U>let vfv_tab=getline("'<")[getpos("'<")[2]-1:getpos("'>")[2]]<CR>
    \:let vfv_ddl = 'vsql -Xtnqc "SELECT EXPORT_OBJECTS('''',''' . vfv_tab . ''')"'<CR>
	\:let vfv_tab .= '.sql'<CR>
    \:execute 'tabnew' vfv_tab<CR>
    \:execute 'r!' . vfv_ddl<CR>
    \gg
noremenu 1.18 PopUp.SQL\ get\ info viW
    \:<C-U>let vfv_tab=getline("'<")[getpos("'<")[2]-1:getpos("'>")[2]]<CR>
    \:let vfv_info='~/.vim/vertica/vfv_info.sh ' . vfv_tab<CR>
	\:let vfv_tab .= '.info'<CR>
    \:execute 'tabnew' vfv_tab<CR>
    \:execute 'r!' . vfv_info<CR>
    \gg
vnoremenu 1.18 PopUp.SQL\ prof :<C-U>execute '''<,''>w!' . vfv_tmp<CR>
    \:tabnew<CR>
    \:execute 'r! ~/.vim/vertica/vfv_prof.sh'<CR>
    \gg
noremenu 1.18 PopUp.VIM\ source\ block y:<C-U>@"<CR>
"noremenu 1.18 PopUp.VIM\ source\ block vip:<C-U>@*<CR>
noremenu 1.18 PopUp.SQL\ running\ jobs :tabnew running_jobs<CR>
    \:execute 'r! vsql -X -qf ~/.vim/vertica/vfv_jobs.sql'<CR>
    \gg
noremenu 1.18 PopUp.SQL\ host\ resources :tabnew host_resources<CR>
    \:execute 'r! vsql -X -x -qf ~/.vim/vertica/vfv_host.sql'<CR>
    \gg
an 1.18 PopUp.-SEP7-			<Nop>
noremenu 1.18 PopUp.SQL\ gen\ select viW
    \:<C-U>let vfv_tab=getline("'<")[getpos("'<")[2]-1:getpos("'>")[2]-1]<CR>
    \:let vfv_cmd='vsql -X -qf ~/.vim/vertica/vfv_select.sql -v arg=' . vfv_tab<CR>
	\:let vfv_tab .= '_select.sql'<CR>
    \:execute 'tabnew' vfv_tab<CR>
    \:execute 'r!' . vfv_cmd<CR>
    \gg
noremenu 1.18 PopUp.SQL\ gen\ where viW
    \:<C-U>let vfv_tab=getline("'<")[getpos("'<")[2]-1:getpos("'>")[2]-1]<CR>
    \:let vfv_cmd='vsql -X -qf ~/.vim/vertica/vfv_where.sql -v arg=' . vfv_tab<CR>
	\:let vfv_tab .= '_where.sql'<CR>
    \:execute 'tabnew' vfv_tab<CR>
    \:execute 'r!' . vfv_cmd<CR>
    \gg
noremenu 1.18 PopUp.SQL\ gen\ insert viW
    \:<C-U>let vfv_tab=getline("'<")[getpos("'<")[2]-1:getpos("'>")[2]-1]<CR>
    \:let vfv_cmd='vsql -X -qf ~/.vim/vertica/vfv_insert.sql -v arg=' . vfv_tab<CR>
	\:let vfv_tab .= '_inserti.sql'<CR>
    \:execute 'tabnew' vfv_tab<CR>
    \:execute 'r!' . vfv_cmd<CR>
    \gg
noremenu 1.18 PopUp.SQL\ gen\ update viW
    \:<C-U>let vfv_tab=getline("'<")[getpos("'<")[2]-1:getpos("'>")[2]-1]<CR>
    \:let vfv_cmd='vsql -X -qf ~/.vim/vertica/vfv_update.sql -v arg=' . vfv_tab<CR>
	\:let vfv_tab .= '_update.sql'<CR>
    \:execute 'tabnew' vfv_tab<CR>
    \:execute 'r!' . vfv_cmd<CR>
    \gg
noremenu 1.18 PopUp.SQL\ gen\ merge viW
    \:<C-U>let vfv_tab=getline("'<")[getpos("'<")[2]-1:getpos("'>")[2]-1]<CR>
    \:let vfv_cmd='vsql -X -qf ~/.vim/vertica/vfv_merge.sql -v arg=' . vfv_tab<CR>
	\:let vfv_tab .= '_merge.sql'<CR>
    \:execute 'tabnew' vfv_tab<CR>
    \:execute 'r!' . vfv_cmd<CR>
    \gg
noremenu 1.18 PopUp.SQL\ gen\ copy viW
    \:<C-U>let vfv_tab=getline("'<")[getpos("'<")[2]-1:getpos("'>")[2]-1]<CR>
    \:let vfv_cmd='vsql -X -qf ~/.vim/vertica/vfv_copy.sql -v arg=' . vfv_tab<CR>
	\:let vfv_tab .= '_copy.sql'<CR>
    \:execute 'tabnew' vfv_tab<CR>
    \:execute 'r!' . vfv_cmd<CR>
    \gg
an 1.19 PopUp.-SEP5-			<Nop>
