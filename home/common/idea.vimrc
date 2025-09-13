" search for actions: :actionlist <patter>

set number                        " line numbers

set hlsearch                      " highlight search occurrences
set ignorecase                    " ignore case in search patterns
set smartcase                     " no ignore case when pattern is uppercase
set incsearch                     " show search results while typing
set wrapscan                      " searches wrap around the end of the file

set gdefault                      " substitute all occurrences in line per default
set history=10000                 " keep x lines of command line history
set scrolloff=5 sidescrolloff=10  " keep some lines before and after the cursor visible
set clipboard=unnamedplus,unnamed,ideaput " integrate with system clipboard

" set multiple-cursors
set commentary
set surround                      " emulate vim-surround plugin


" set <leader> to <space>
let mapleader = " "

" edit ideavim config
nnoremap <leader>vv :e ~/.ideavimrc<CR>
nnoremap <leader>vr :source ~/.ideavimrc<CR>

""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Fix some vim annoyances

" make Y behave like D and C, yanking till end of line
map Y y$

" don't overwrite register when pasting over selection
vnoremap p pgvy

" paste over rest of line
" nnoremap <leader>p v$<Left>pgvy
nnoremap <leader>p v$<Left>p

" don't lose selection when indenting
vnoremap < <gv
vnoremap > >gv
vnoremap = =gv

" TODO: smart home
nmap <Home> ^
imap <silent> <Home> <C-O>^
unmap <c-t>

""""""""""""""""""""""""""""""""""""""""""""""""""""
" Custom bindings

" clear search highlighting
nnoremap <leader>h :nohls<return><esc>

""""""""""""""""""""""""""""""""""""""""""""""""""""
" IDEA specific
nmap <leader>? :action GotoAction<CR>

" change font size
nmap + :action EditorIncreaseFontSize<CR>
nmap - :action EditorDecreaseFontSize<CR>
nmap <leader>= :action EditorResetFontSize<CR>

" code navigation

" https://youtrack.jetbrains.com/issue/VIM-44
nnoremap <c-o> :action Back<cr>
nnoremap <c-i> :action Forward<cr>

nnoremap <C-d> <C-d>zz
nnoremap <C-u> <C-u>zz

nmap <leader>e :action GotoFile<CR>
nmap <leader>a :action FindInPath<CR>
nmap gr :action ShowUsages<CR>
nmap gi :action GotoImplementation<CR>
nmap gs :action GotoSuperMethod<CR>

nmap <C-p> :action ParameterInfo<CR>
imap <C-p> <C-o>:action ParameterInfo<CR>
nmap <leader>n :action GotoNextError<CR>


nmap <leader>ri :action Inline<CR>
nmap <leader>rr :action RenameElement<CR>
nmap <leader>rev :action IntroduceVariable<CR>
vmap <leader>rev :action IntroduceVariable<CR>
nmap <leader>rem :action ExtractMethod<CR>
vmap <leader>rem :action ExtractMethod<CR>
nmap <leader>rm :action Move<CR>
nmap <leader>ro :action OptimizeImports<CR>
nmap <leader>rG :action Generate<CR>

nmap <leader>lf :action ReformatCode<CR>

nmap <, :action MoveElementLeft<CR>
nmap >, :action MoveElementRight<CR>

nmap <leader>gr :action Vcs.RollbackChangedLines<CR>
