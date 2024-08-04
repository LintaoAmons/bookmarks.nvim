local _repo = require("bookmarks.repo")
local _bookmark_list = require("bookmarks.domain").bookmark_list
local READ = {}
local WRITE = {}

---@return Bookmarks.BookmarkList[]
local function find_all()
  return _repo.db.get().bookmark_lists or {}
end

function READ.find_all()
  local bookmark_lists = find_all()
  local all = {}
  for _, bookmark_list in pairs(bookmark_lists) do
    local bl = _bookmark_list.get_all_marks(bookmark_list)
    for _, bookmark in ipairs(bl) do
      bookmark.listname = bookmark_list.name
      table.insert(all, bookmark)
    end
  end
  return all
end

return {
  read = READ,
  write = WRITE,
}
