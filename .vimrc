
"*****************************************************************************
"""" dein.vim
"*****************************************************************************
"" プラグインが実際にインストールされるディレクトリ
let s:dein_dir = expand('~/dotfiles/.cache/dein')
" dein.vim 本体
let s:dein_repo_dir = s:dein_dir . '/repos/github.com/Shougo/dein.vim'

" dein.vim がなければ github から落としてくる
if &runtimepath !~# '/dein.vim'
	if !isdirectory(s:dein_repo_dir)
		execute '!git clone https://github.com/Shougo/dein.vim' s:dein_repo_dir
	endif
	execute 'set runtimepath^=' . fnamemodify(s:dein_repo_dir, ':p')
endif

" 設定開始
if dein#load_state(s:dein_dir)
	call dein#begin(s:dein_dir)

	" プラグインリストを収めた TOML ファイル
	" 予め TOML ファイル（後述）を用意しておく
	let g:rc_dir    = expand('~/dotfiles/.vim/rc')
	let s:toml      = g:rc_dir . '/dein.toml'
	let s:lazy_toml = g:rc_dir . '/dein_lazy.toml'

	" TOML を読み込み、キャッシュしておく
	call dein#load_toml(s:toml,      {'lazy': 0})
	call dein#load_toml(s:lazy_toml, {'lazy': 1})

	" 設定終了
	call dein#end()
	call dein#save_state()
endif

"もし、未インストールものものがあったらインストール
if dein#check_install()
	call dein#install()
endif

"*****************************************************************************
""" Visual Settings
"*****************************************************************************
syntax enable
set background=dark
set t_Co=256
colorscheme iceberg
set number
set ruler

""*****************************************************************************
"" Abbreviations
"*****************************************************************************
""" NERDTree
let g:NERDTreeChDirMode=2
let g:NERDTreeIgnore=['\.rbc$', '\~$', '\.pyc$', '\.db$', '\.sqlite$', '__pycache__', 'node_modules', 'bower_components']
let g:NERDTreeSortOrder=['^__\.py$', '\/$', '*', '\.swp$', '\.bak$', '\~$']
let g:NERDTreeShowBookmarks=1
let g:nerdtree_tabs_focus_on_files=1
let g:NERDTreeMapOpenInTabSilent = '<RightMouse>'
let g:NERDTreeWinSize = 20
set wildignore+=*/tmp/*,*.so,*.swp,*.zip,*.pyc,*.db,*.sqlite
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
nnoremap <silent> <leader>nf :NERDTreeFind<CR>
noremap <C-n> :NERDTreeToggle<CR>

""*****************************************************************************
""" quickrun
""*****************************************************************************
let g:quickrun_config = {
  \ 'python': {
  \   'command': 'python3'
  \ },
  \ }


"" quickrunのランナーにvimprocを使用する
"" 成功時はバッファへ
"" エラー時はquickfixへ出力
let g:quickrun_config._ = {
\   'runner'    : 'vimproc',
\   'runner/vimproc/updatetime' : 60,
\   'outputter' : 'error',
\   'outputter/error/success' : 'buffer',
\   'outputter/error/error'   : 'quickfix',
\   'outputter/buffer/split'  : ':rightbelow 8sp',
\   'outputter/buffer/close_on_empty' : 1,
\}

""*****************************************************************************
"" Syntacs
"*****************************************************************************
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
let g:syntastic_python_checkers = ['pycodestyle']
let g:syntastic_python3_checkers = ['pep8']
