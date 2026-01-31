return {
	{
		"bjarneo/aether.nvim",
		name = "aether",
		priority = 1000,
		opts = {
			disable_italics = false,
			colors = {
				-- Monotone shades (base00-base07)
				base00 = "#121212", -- Default background
				base01 = "#383735", -- Lighter background (status bars)
				base02 = "#121212", -- Selection background
				base03 = "#595c68", -- Comments, invisibles
				base04 = "#dbd9d3", -- Dark foreground
				base05 = "#bcb9b2", -- Default foreground
				base06 = "#a4a4a4", -- Light foreground
				base07 = "#dbd9d3", -- Light background

			-- Accent colors (base08-base0F)
			base08 = "#e8a0a0", -- Variables, errors - pastel coral/red
			base09 = "#e8c08a", -- Integers, constants - pastel peach
			base0A = "#e8d8a0", -- Classes, types - pastel gold
			base0B = "#a8d4a8", -- Strings - pastel sage green
			base0C = "#a8d4d4", -- Support, regex - pastel teal
			base0D = "#a8c0d8", -- Functions, keywords - pastel sky blue
			base0E = "#d0a8d0", -- Keywords, storage - pastel lavender
			base0F = "#d4a8a0", -- Deprecated - pastel dusty rose
			},
		},
	},
	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = "aether",
		},
	},
}
