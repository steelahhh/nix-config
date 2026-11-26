set number

set hlsearch
set ignorecase
set smartcase
set incsearch
set wrapscan

set gdefault
set history=10000
set scrolloff=5 sidescrolloff=10
set clipboard=unnamedplus,unnamed,ideaput

set commentary
set surround

let mapleader = " "

nnoremap <leader>vv :e ~/.ideavimrc<CR>
nnoremap <leader>vr :source ~/.ideavimrc<CR>

map Y y$

vnoremap p pgvy

nnoremap <leader>p v$<Left>p

vnoremap < <gv
vnoremap > >gv
vnoremap = =gv

nmap <Home> ^
imap <silent> <Home> <C-O>^
unmap <c-t>

nnoremap <leader>h :nohls<return><esc>

nmap <leader>? :action GotoAction<CR>

nmap + :action EditorIncreaseFontSize<CR>
nmap - :action EditorDecreaseFontSize<CR>
nmap <leader>= :action EditorResetFontSize<CR>

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
