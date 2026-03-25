return {
	'christoomey/vim-tmux-navigator',
	lazy = false,
	keys = {
		{ '<C-j>', '<cmd> TmuxNavigateLeft<cr>', desc='window left' },
		{ '<C-j>', '<cmd> TmuxNavigateRight<cr>', desc='window right' },
		{ '<C-j>', '<cmd> TmuxNavigateUp<cr>', desc='window up' },
		{ '<C-j>', '<cmd> TmuxNavigateDown<cr>', desc='window down' },
	}
}
