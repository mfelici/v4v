# Vim for Vertica (V4V)
When the [best editor](www.vim.org) meets the [best database](www.vertica.com)...

## What is V4V 
V4V stands for *Vim for Vertica*. It's a set of VIM plugins and syntax files in order to: 
- Highlight SQL Vertica "the right way" 
- Format SQL commands 
- Run vsql from within VIM getting the results back in VIM 
- Copy SQL snippets in HTML format into your clipboard 

## What V4V consists of 
V4V consists of: 
- VIM Syntax file: ```sqlvertica.vim```
- VIM File Type plugin: ```sql.vim```
- settings to be added to your VIM initialization file: ```.vimrc``` 

## Which tools are used by V4V 
V4V uses: 
- ```vsql``` to run you SQL commands. By default vsql is executed with the following options: 
  o ```-X``` to exclude local vsqlrc 
  o ```-i``` to add execution elapsed 
  o ```vsql``` uses standard ```VSQL_USER``, ```VSQL_PASSWORD```, ```VSQL_HOST```, etc settings. 
- A SQL formatter called ```sqlformat``` (see in the following section how to install it) 
-  ```xclip```(Linux)/```pbcopy```(Mac) tool to copy formatted SQL to your clipboard 
- ```sed``` to manipulate the SQL Interpreter (```vsql``` by default) output
- GraphViz's ```dot``` to transform the Vertica EXPLAIN plan into a graph
- ```xdg-open``` (Linux) or ```open``` to run the PDF visualizer installed on your system

You are free to use a different SQL clients and/or SQL formatters by changing the ``sql.vim`` file type plugin. 

## How to Install V4V 
### V4V Prerequisites
V4V uses an external SQL formatter. You can use any SQL formatter you like as long as you change the default ```sqlformat``` call in the V4V's sql.vim plugin file.
The default formatter (```sqlformat```) can be installed on Linux/Mac as follows:
- Download```python-sqlparse``` from https://github.com/andialbrecht/sqlparse 
- Install the python setup tools: ```sudo apt install python-setuptools```  
- Install sqlparse: ```cd sqlparse-master && sudo python setup.py install``` 
- Unzip sqlparse archihve: ```unzip sqlparse-master.zip``` 

This will create the /usr/local/bin/sqlformat executable which is then used by V4V. This tool has several options; check them with ```sqlfmt --help```. The ones used by default in V4V are:
``` 
    sqlformat -k upper 
              -s 
              -r 
             --indent_width 4 
             --indent_columns.
```
You can change default sqlformat behaviour to better suit your needs by modifying V4V's ```sql.vim``` plugin. 

V4V also uses ```xclip```(Linux) or ```pbcopy``` (Mac) to copy formatted and syntax highlighted SQL into your clipboard. To installl ```xclip``` under Ubuntu/Debian: ```sudo apt install xclip```.
Mac version doesn't need any installation because ```pbcopy``` is available by default.

And, finally, to produce the graphical EXPLAIN plan, V4V uses GraphViz.More specifically the program ```dot```. The installation of this product depends on your operating system... it could be ```sudo apt install graphviz``` under Linux Ubuntu, ```sudo yum install graphviz``` under Linux CentOS or ```brew install graphviz``` on your Mac.

## V4V Installation in 4 easy steps

 - Step 1: Create a backup copy of your ```.vimrc``` before modifying it. 
 - Step 2:   *merge*  ```sample.vimrc``` with your pre-existing copy. The important settings are: 
```vim
let g:sql_type_default = 'sqlvertica'
nnoremap <Tab> za " Toggle to expand/close folds 
menu 20.351 Edit.Copy\ to\ HTML :'<,'>Copy2HTML<CR> 
vnoremenu 1.31 PopUp.Copy\ to\ HTML :'<,'>Copy2HTML<CR> 
```
And the ```CopyToHTML``` function to copy formatted SQL:
```vim
function! CopyToHTML(line1, line2)
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
    w !pbcopy " Mac: pbcopy, Linux: xclip -selection clipboard
    q!  
endfunction
command! -range=% Copy2HTML :silent call CopyToHTML(<line1>,<line2>)
```

- Step 3: copy V4V's syntax file ```sqlvertica.vim``` under ```~/.vim/syntax/```  (create this directory if doesn't exist) 
- Step 4: copy V4V's File Type plugin ```sql.vim``` under ``~/.vim/after/ftplugin```  (create this directory if doesn't exist) 


## How to use V4V 
Start vim (or its GUI version gvim) and open your SQL file 

- To FORMAT your SQL: 
	- Select the lines containing the SQL to be formatted 
   - Hit F3 or (gvim): right click and select ```SQL Format``` 
- To RUN your SQL: 
   - Select the lines containing the SQL you want to run 
   - Hit F4 or (gvim): right click and select ```SQL run```    
- To EXPLAIN your SQL: 
   - Select the lines containing the SQL you want to EXPLAIN 
   - Hit F5 or (gvim): right click and select ```SQL explain text``` 
- To get the graphical EXPLAIN of your SQL: 
   - Select the lines containing the SQL you want to EXPLAIN 
   - Hit F6 or (gvim): right click and select ```SQL explain graph``` 
- To EXPAND/CLOSE the result set:  
   - Hit TAB 
- To COPY your SQL snippet to HTML: 
   - Select the lines you want to copy 
   - Run :```'<,'>Copy2HTML<CR>``` or (gvim): right click and select ```Copy to HTML``` 

## How to customize V4V
As we said Vim for Vertica uses - by default - ```vsql``` to interact with Vertica. Sometimes you might want to change the standard environment variables used by ```vsql``` in V4V to use a different database, or a different host or user.  
 - to check all environment variables used by VSQL: ```:!set | grep VSQL_```
- to check  individual variables use, for example: ```:echo $VSQL_USER```

To set or change a VSQL environment variable:
 - ```:let $VSQL_DATABASE="<my db name>"```
 - ```:let $VSQL_HOST="<my Vertica host>"```
 - ```:let $VSQL_PASSWORD="<my secret password>"```
 - ```:let $VSQL_PORT="5433"```
 - ```:let $VSQL_USER="<my user>"```

You might also want to customise:
- the default prefix used by V4V to identify (and fold) commands output: ```:let  vfv_pfx="-- out "``` 
- the default location for the temporary files created by VfV: ```let vfv_tmp="~/._vfv.sql"```
- the default SQL execution command: ```:let  vfv_sql="vsql -X -i -f "  . vfv_tmp .  " 2>&1"```
- the default SQL formatter call: ```:let  vfv_fmt="sqlformat -k upper -s -r --indent_width 4 --indent_columns -"```


