-- service_test.lua
local M = {}
local service = require("bookmarks.domain.service")
local repo = require("bookmarks.domain.repo")

local function clean_up()
  repo._DB.nodes:drop()
  repo._DB.node_relationships:drop()
  repo._DB.active_list:drop()
  repo.setup()
end

M.test_mark_with_parent = function()
  -- Create a list first
  ---@type Bookmarks.NewNode
  local list = {
    type = "list",
    name = "Test List",
    children = {},
    created_at = os.time(),
  }
  local list_id = repo.insert_node(list)

  -- Create bookmark with explicit parent
  local bookmark = service.mark("Test Bookmark", list_id)

  -- Verify bookmark
  assert(bookmark ~= nil, "Bookmark should be created")
  assert(bookmark.name == "Test Bookmark", "Bookmark should have correct name")
  assert(bookmark.type == "bookmark", "Should be a bookmark type")

  -- Verify parent relationship
  local list_node = repo.find_node(list_id)
  assert(list_node ~= nil, "List should exist")
  assert(#list_node.children == 1, "List should have one child")
  assert(list_node.children[1].id == bookmark.id, "Bookmark should be child of list")
end

M.test_mark_with_active_list = function()
  -- Create a list and set it active
  ---@type Bookmarks.NewNode
  local list = {
    type = "list",
    name = "Active List",
    children = {},
    created_at = os.time(),
  }
  local list_id = repo.insert_node(list)
  repo.set_active_list(list_id)

  -- Create bookmark without parent (should use active list)
  local bookmark = service.mark("Test Bookmark")

  -- Verify bookmark
  assert(bookmark ~= nil, "Bookmark should be created")
  assert(bookmark.name == "Test Bookmark", "Bookmark should have correct name")

  -- Verify it's in the active list
  local active_list = repo.get_active_list()
  assert(#active_list.children == 1, "Active list should have one child")
  assert(active_list.children[1].id == bookmark.id, "Bookmark should be in active list")
end

M.test_mark_no_active_list = function()
  clean_up()
  -- Should use root list when no active list
  local bookmark = service.mark("Test Bookmark")

  -- Verify bookmark
  assert(bookmark ~= nil, "Bookmark should be created")
  assert(bookmark.name == "Test Bookmark", "Bookmark should have correct name")

  -- Verify it's in root list
  local root = repo.find_node(0)
  assert(root ~= nil, "Root list should exist")
  assert(#root.children == 1, "Root list should have one child")
  assert(root.children[1].id == bookmark.id, "Bookmark should be in root list")
end

M.test_create_list_root = function()
  -- Create list without parent (should use root)
  local list = service.create_list("Root Child List")

  -- Verify list
  assert(list ~= nil, "List should be created")
  assert(list.name == "Root Child List", "List should have correct name")
  assert(list.type == "list", "Should be a list type")

  -- Verify it's in root list
  local root = repo.find_node(0)
  assert(root ~= nil, "Root list should exist")
  assert(root.children[#root.children].id == list.id, "List should be in root list")
end

M.test_create_list_with_parent = function()
  clean_up()
  -- Create a parent list first
  local parent_list = service.create_list("Parent List")

  -- Create child list
  local child_list = service.create_list("Child List", parent_list.id)

  -- Verify child list
  assert(child_list ~= nil, "List should be created")
  assert(child_list.name == "Child List", "List should have correct name")
  assert(child_list.type == "list", "Should be a list type")

  -- Verify parent relationship
  local parent = repo.find_node(parent_list.id)
  assert(parent ~= nil, "Parent list should exist")
  assert(#parent.children == 1, "Parent should have one child")
  assert(parent.children[1].id == child_list.id, "Child list should be child of parent")
end

M.test_rename_bookmark = function()
  -- Create a bookmark first
  local bookmark = service.mark("Original Name")

  -- Rename the bookmark
  local updated = service.rename_node(bookmark.id, "New Name")

  -- Verify rename
  assert(updated ~= nil, "Bookmark should exist after rename")
  assert(updated.id == bookmark.id, "Should be the same bookmark")
  assert(updated.name == "New Name", "Name should be updated")
  assert(updated.type == "bookmark", "Type should remain bookmark")

  -- Verify persistence
  local found = repo.find_node(bookmark.id)
  assert(found ~= nil, "bookmark should exist after rename")
  assert(found.name == "New Name", "Name should be persisted")
end

M.test_rename_list = function()
  -- Create a list first
  local list = service.create_list("Original List Name")

  -- Rename the list
  local updated = service.rename_node(list.id, "New List Name")

  -- Verify rename
  assert(updated ~= nil, "List should exist after rename")
  assert(updated.id == list.id, "Should be the same list")
  assert(updated.name == "New List Name", "Name should be updated")
  assert(updated.type == "list", "Type should remain list")

  -- Verify persistence
  local found = repo.find_node(list.id)
  assert(found ~= nil, "List should exist after rename")
  assert(found.name == "New List Name", "Name should be persisted")
end

M.test_rename_nonexistent_node = function()
  -- Try to rename a node that doesn't exist
  local status, error = pcall(function()
    service.rename_node(99999, "New Name")
  end)

  assert(not status, "Should throw an error")
  assert(string.match(error, "Node not found"), "Should have correct error message")
end
-- Run all tests
-- :lua require("bookmarks.test.service-test").run_all_tests()
M.run_all_tests = function()
  local tests = {
    { name = "test_mark_with_parent", fn = M.test_mark_with_parent },
    { name = "test_mark_with_active_list", fn = M.test_mark_with_active_list },
    { name = "test_mark_no_active_list", fn = M.test_mark_no_active_list },
    { name = "test_create_list_with_parent", fn = M.test_create_list_with_parent },
    { name = "test_create_list_root", fn = M.test_create_list_root },
    { name = "test_rename_bookmark", fn = M.test_rename_bookmark },
    { name = "test_rename_list", fn = M.test_rename_list },
    { name = "test_rename_nonexistent_node", fn = M.test_rename_nonexistent_node },
  }

  print("\nRunning service mark tests...\n")
  local passed = 0
  local failed = 0
  local failed_tests = {}

  for _, test in ipairs(tests) do
    print(string.format("Running %s...", test.name))
    clean_up()

    local status, error = pcall(test.fn)
    if status then
      passed = passed + 1
      print(string.format("✅ %s passed\n", test.name))
    else
      failed = failed + 1
      table.insert(failed_tests, { name = test.name, error = error })
      print(string.format("❌ %s failed\n", test.name))
    end
  end

  print(string.format("\nTest Results: %d passed, %d failed", passed, failed))

  if #failed_tests > 0 then
    print("\nFailed tests:")
    for _, failure in ipairs(failed_tests) do
      print(string.format("\n%s:\n%s", failure.name, failure.error))
    end
  end
end

return M
