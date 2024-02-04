local repo = require("bookmarks.repo")
local ns_name = "BookmarksNvim"
local sign_name = "BookmarksNvimSign"
local sign_icon = "󰃁"
local ns = vim.api.nvim_create_namespace(ns_name)

vim.fn.sign_define(sign_name, { text = sign_icon, texthl = sign_name })
vim.api.nvim_set_hl(0, sign_name, { foreground = "grey" }) -- control the color of the sign

---@param line number
local function place_sign(line, buf_number, desc)
	vim.fn.sign_place(line, ns_name, sign_name, buf_number, { lnum = line })
	local at_end = -1
	vim.api.nvim_buf_set_extmark(buf_number, ns, line - 1, at_end, {
		virt_text = { { "  " .. desc, sign_name } },
		virt_text_pos = "overlay",
		hl_mode = "combine",
	})
end

---@param bookmarks? Bookmarks.Bookmark[]
local function refresh_signs(bookmarks)
	bookmarks = bookmarks or repo.find_or_set_active_bookmark_list().bookmarks
	local buf_number = vim.api.nvim_get_current_buf()
	for _, bookmark in ipairs(bookmarks) do
		local filepath = vim.fn.expand("%:p")
		if filepath == bookmark.location.path then
			pcall(place_sign, bookmark.location.line, buf_number, bookmark.name)
		end
	end
end

local function bookmark_sign_autocmd()
	-- TODO: check the autocmd
	vim.api.nvim_create_augroup(ns_name, { clear = true })
	vim.api.nvim_create_autocmd({ "BufWinEnter", "BufEnter" }, {
		group = ns_name,
		callback = function(_)
			refresh_signs()
		end,
	})
end

return {
	bookmark_sign_autocmd = bookmark_sign_autocmd,
	refresh_signs = refresh_signs,
}
