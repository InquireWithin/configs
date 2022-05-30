syntax on "enable automatic syntax highlighting when a file is opened in vim
filetype plugin indent on
"all files except for makefiles and C/C++ indents will use a 4-space tab. Otherwise, use 8-width tab character
"auto-command support req'd
if has ("autocmd")
    autocmd FileType make set tabstop=8 shiftwidth=8 softtabstop=0 noexpandtab
endif
set tabstop=4 "tab is 4 spaces width
set shiftwidth=4 " > indents are 4 spaces widt
set softtabstop=4 "num of columns for a tab
set expandtab "tab key should be interpreted as inserting 4 spaces

"lines and line numbers
set relativenumber
"text wrap for num columns
set cpoptions+=n
"gutter column width change
set numberwidth=2

"mouse support
set mouse=a

































