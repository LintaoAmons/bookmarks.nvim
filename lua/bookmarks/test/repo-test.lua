-- TODO: test against  test_db_path
if true then
  return
end

local M = {}
local repo = require("bookmarks.domain.repo")
local test_db_path = vim.fn.stdpath("data") .. "/bookmarks.sqlite.test.db"

local function clean_up()
  repo._DB.nodes:drop()
  repo._DB.node_relationships:drop()
  repo._DB.active_list:drop()
end

-- Basic setup and find tests
M.test_setup = function()
  repo.setup(test_db_path)
  clean_up()
  repo.setup(test_db_path)
  local root = repo.find_node(0)
  assert(root ~= nil, "Should create root node")
  assert(root.name == "root", "Should create root node")
end

M.test_find_node_not_exist = function()
  local node = repo.find_node(999999)
  assert(node == nil, "Should return nil if node doesn't exist")
end

M.test_find_node_exist = function()
  local found = repo.find_node(0)
  assert(found ~= nil, "Should return node if node exists")
  assert(found.id == 0, "id should be the same")
end

-- Insert node tests
M.test_insert_bookmark = function()
  M.test_setup()
  ---@type Bookmarks.NewNode
  local node = {
    type = "bookmark",
    name = "Test Bookmark",
    location = {
      path = "test.lua",
      line = 10,
      col = 1,
    },
    children = {},
    created_at = os.time(),
  }

  local id = repo.insert_node(node)
  local saved = repo.find_node(id)
  assert(saved ~= nil, "Should find node")
  assert(saved.name == "Test Bookmark", "Should preserve node properties")
  assert(saved.location.path == "test.lua", "Should preserve node location")
end

M.test_insert_list = function()
  M.test_setup()
  ---@type Bookmarks.NewNode
  local node = {
    type = "list",
    name = "Test List",
    children = {},
    created_at = os.time(),
    is_expanded = true,
  }

  local id = repo.insert_node(node)
  local saved = repo.find_node(id)
  assert(saved ~= nil, "Should find node")
  assert(saved.type == "list", "Should preserve node type")
  assert(saved.name == "Test List", "Should preserve node properties")
  assert(saved.is_expanded == true, "Should preserve active state")
end

-- :lua require("bookmarks.test.repo_test").test_update_node_name()
M.test_update_node_name = function()
  M.test_setup()
  ---@type Bookmarks.NewNode
  local node = {
    type = "bookmark",
    name = "Original Name",
    created_at = os.time(),
    children = {},
  }

  local id = repo.insert_node(node)
  local before = repo.find_node(id)
  assert(before ~= nil, "should find node")
  before.name = "New Name"
  repo.update_node(before)
  local updated = repo.find_node(id)
  assert(updated ~= nil, "should find node")
  assert(updated.name == "New Name", "Name should be updated")
end

-- Test delete_node
M.test_delete_node = function()
  M.test_setup()
  -- Create a test bookmark
  ---@type Bookmarks.NewNode
  local bookmark = {
    type = "bookmark",
    name = "To Delete",
    created_at = os.time(),
    children = {},
  }
  local bookmark_id = repo.insert_node(bookmark)

  -- Create a list and add bookmark to it
  ---@type Bookmarks.NewNode
  local list = {
    type = "list",
    name = "Test List",
    children = {},
    created_at = os.time(),
  }
  local list_id = repo.insert_node(list)
  repo.add_to_list(bookmark_id, list_id)

  -- Delete the bookmark
  repo.delete_node(bookmark_id)

  -- Verify bookmark is deleted
  local deleted_node = repo.find_node(bookmark_id)
  assert(deleted_node == nil, "Node should be deleted")

  -- Verify relationships are deleted
  local list_nodes = repo.find_node(list_id)
  assert(#list_nodes == 0, "List should have no nodes")
end

M.test_add_to_list = function()
  M.test_setup()
  -- Create a list
  ---@type Bookmarks.NewNode
  local list = {
    type = "list",
    name = "Test List",
    children = {},
    created_at = os.time(),
    is_expanded = true,
  }
  local list_id = repo.insert_node(list)

  -- Create a bookmark
  ---@type Bookmarks.NewNode
  local bookmark = {
    type = "bookmark",
    name = "Test Bookmark",
    created_at = os.time(),
    children = {},
  }
  local bookmark_id = repo.insert_node(bookmark)

  repo.add_to_list(bookmark_id, list_id)
  local list_nodes = repo.find_node(list_id)
  assert(list_nodes ~= nil, "List should exist")
  assert(#list_nodes.children == 1, "List should have one node")
  assert(list_nodes.children[1].id == bookmark_id, "Bookmark should be in list")
end

-- Test remove_from_list
M.test_remove_from_list = function()
  M.test_setup()
  -- Create a list
  ---@type Bookmarks.NewNode
  local list = {
    type = "list",
    name = "Test List",
    children = {},
    created_at = os.time(),
  }
  local list_id = repo.insert_node(list)

  -- Create a bookmark and add to list
  ---@type Bookmarks.NewNode
  local bookmark = {
    type = "bookmark",
    name = "Test Bookmark",
    created_at = os.time(),
    children = {},
  }
  local bookmark_id = repo.insert_node(bookmark, list_id)

  -- Verify initial state
  local initial_nodes = repo.find_node(list_id)
  assert(initial_nodes ~= nil, "List should exist")

  -- Remove from list
  repo.remove_from_list(bookmark_id, list_id)

  -- Verify bookmark is removed from list but still exists
  local list_nodes = repo.find_node(list_id)
  assert(list_nodes ~= nil, "List should exist")
  assert(#list_nodes.children == 0, "List should have no nodes")

  local bookmark_node = repo.find_node(bookmark_id)
  assert(bookmark_node ~= nil, "Bookmark should still exist")
end

-- Test get_all_bookmarks
M.test_get_all_bookmarks = function()
  M.test_setup()
  -- Create multiple bookmarks in different lists
  ---@type Bookmarks.NewNode
  local list1 = {
    type = "list",
    name = "List 1",
    children = {},
    created_at = os.time(),
  }
  local list1_id = repo.insert_node(list1)

  ---@type Bookmarks.NewNode
  local list2 = {
    type = "list",
    name = "List 2",
    children = {},
    created_at = os.time(),
  }
  local list2_id = repo.insert_node(list2)

  -- Create bookmarks
  local bookmark_names = { "Bookmark 1", "Bookmark 2", "Bookmark 3" }
  local bookmark_ids = {}

  for i, name in ipairs(bookmark_names) do
    ---@type Bookmarks.NewNode
    local bookmark = {
      type = "bookmark",
      name = name,
      created_at = os.time(),
      children = {},
    }
    local list_id = i <= 2 and list1_id or list2_id
    local id = repo.insert_node(bookmark, list_id)
    table.insert(bookmark_ids, id)
  end

  -- Get all bookmarks
  local all_bookmarks = repo.get_all_bookmarks()

  -- Verify results
  assert(#all_bookmarks == 3, "Should find all bookmarks")
  local found_names = {}
  for _, bookmark in ipairs(all_bookmarks) do
    table.insert(found_names, bookmark.name)
  end
  table.sort(found_names)
  assert(found_names[1] == "Bookmark 1", "Should find Bookmark 1")
  assert(found_names[2] == "Bookmark 2", "Should find Bookmark 2")
  assert(found_names[3] == "Bookmark 3", "Should find Bookmark 3")
end

-- Test update_node
M.test_update_node = function()
  M.test_setup()
  -- Create a test bookmark
  ---@type Bookmarks.NewNode
  local bookmark = {
    type = "bookmark",
    name = "Original Name",
    description = "Original description",
    location = {
      path = "original.lua",
      line = 1,
      col = 1,
    },
    created_at = os.time(),
    children = {},
  }
  local bookmark_id = repo.insert_node(bookmark)

  -- Get the node and modify it
  local node = repo.find_node(bookmark_id)
  node.name = "Updated Name"
  node.description = "Updated description"
  node.location = {
    path = "updated.lua",
    line = 2,
    col = 2,
  }

  -- Update the node
  local updated = repo.update_node(node)

  -- Verify updates
  assert(updated.name == "Updated Name", "Name should be updated")
  assert(updated.description == "Updated description", "Description should be updated")
  assert(updated.location.path == "updated.lua", "Location path should be updated")
  assert(updated.location.line == 2, "Location line should be updated")
  assert(updated.location.col == 2, "Location column should be updated")
end

-- Test setting and getting active list
M.test_active_list = function()
  M.test_setup()
  -- Create two lists
  ---@type Bookmarks.NewNode
  local list1 = {
    type = "list",
    name = "List 1",
    children = {},
    created_at = os.time(),
  }
  local list1_id = repo.insert_node(list1)

  ---@type Bookmarks.NewNode
  local list2 = {
    type = "list",
    name = "List 2",
    children = {},
    created_at = os.time(),
  }
  local list2_id = repo.insert_node(list2)

  -- Set list1 as active
  repo.set_active_list(list1_id)
  local active1 = repo.get_active_list()
  assert(active1 ~= nil, "Should have an active list")
  assert(active1.id == list1_id, "List1 should be active")

  -- Set list2 as active (should replace list1)
  repo.set_active_list(list2_id)
  local active2 = repo.get_active_list()
  assert(active2 ~= nil, "Should have an active list")
  assert(active2.id == list2_id, "List2 should be active")

  -- Verify only one active list exists
  local active_count = #repo._DB.active_list:get()
  assert(active_count == 1, "Should only have one active list")

  -- Test invalid list ID
  local status, _ = pcall(repo.set_active_list, 99999)
  assert(not status, "Should error on invalid list ID")
end

M.test_active_list_default_root = function()
  M.test_setup()

  -- Initially should return root list
  local active = repo.get_active_list()
  assert(active ~= nil, "Should return root list")
  assert(active.id == 0, "Should return root list with id 0")
  assert(active.type == "list", "Root should be a list")
  assert(active.name == "root", "Should be named 'root'")

  -- Create and set a new active list
  ---@type Bookmarks.NewNode
  local list = {
    type = "list",
    name = "Test List",
    children = {},
    created_at = os.time(),
  }
  local list_id = repo.insert_node(list)
  repo.set_active_list(list_id)

  -- Should return new active list
  local new_active = repo.get_active_list()
  assert(new_active.id == list_id, "Should return new active list")
end

M.test_find_node_by_location = function()
  M.test_setup()
  -- Create a test bookmark with location
  ---@type Bookmarks.NewNode
  local bookmark = {
    type = "bookmark",
    name = "Test Location Bookmark",
    location = {
      path = "/test/file.lua",
      line = 42,
      col = 10,
    },
    created_at = os.time(),
    children = {},
  }

  -- Insert the bookmark
  local bookmark_id = repo.insert_node(bookmark)

  -- Test finding the node by exact location
  local found = repo.find_node_by_location({
    path = "/test/file.lua",
    line = 42,
    col = 10,
  })

  assert(found ~= nil, "Should find node with matching location")
  assert(found.id == bookmark_id, "Should find correct node")
  assert(found.location.path == "/test/file.lua", "Should match path")
  assert(found.location.line == 42, "Should match line")
  assert(found.location.col == 10, "Should match column")

  -- Test finding the node with different column
  local found_diff_col = repo.find_node_by_location({
    path = "/test/file.lua",
    line = 42,
    col = 999, -- Different column number
  })

  assert(found_diff_col ~= nil, "Should find node regardless of column number")
  assert(found_diff_col.id == bookmark_id, "Should find same node with different column")

  -- Test with non-existent location
  local not_found = repo.find_node_by_location({
    path = "/nonexistent/file.lua",
    line = 1,
    col = 1,
  })

  assert(not_found == nil, "Should return nil for non-existent location")
end

M.test_find_bookmarks_by_path = function()
  M.test_setup()
  -- Create a test list
  ---@type Bookmarks.NewNode
  local list = {
    type = "list",
    name = "Test List",
    children = {},
    created_at = os.time(),
  }
  local list_id = repo.insert_node(list)
  repo.set_active_list(list_id)

  -- Create multiple bookmarks with same path in different lists
  local test_path = "/test/file.lua"

  -- Create bookmarks in our test list
  ---@type Bookmarks.NewNode
  local bookmark1 = {
    type = "bookmark",
    name = "Bookmark 1",
    location = {
      path = test_path,
      line = 10,
      col = 1,
    },
    created_at = os.time(),
    children = {},
  }
  local bookmark1_id = repo.insert_node(bookmark1, list_id)

  ---@type Bookmarks.NewNode
  local bookmark2 = {
    type = "bookmark",
    name = "Bookmark 2",
    location = {
      path = test_path,
      line = 20,
      col = 1,
    },
    created_at = os.time(),
    children = {},
  }
  local bookmark2_id = repo.insert_node(bookmark2, list_id)

  -- Create a bookmark in another list
  ---@type Bookmarks.NewNode
  local other_list = {
    type = "list",
    name = "Other List",
    children = {},
    created_at = os.time(),
  }
  local other_list_id = repo.insert_node(other_list)

  ---@type Bookmarks.NewNode
  local bookmark3 = {
    type = "bookmark",
    name = "Bookmark 3",
    location = {
      path = test_path,
      line = 30,
      col = 1,
    },
    created_at = os.time(),
    children = {},
  }
  local bookmark3_id = repo.insert_node(bookmark3, other_list_id)

  -- Test finding bookmarks in active list (default behavior)
  local found_bookmarks = repo.find_bookmarks_by_path(test_path)
  assert(#found_bookmarks == 2, "Should find 2 bookmarks in active list")
  assert(found_bookmarks[1].id == bookmark1_id or found_bookmarks[2].id == bookmark1_id, "Should find bookmark1")
  assert(found_bookmarks[1].id == bookmark2_id or found_bookmarks[2].id == bookmark2_id, "Should find bookmark2")

  -- Test finding bookmarks in specific list
  local other_list_bookmarks = repo.find_bookmarks_by_path(test_path, other_list_id)
  assert(#other_list_bookmarks == 1, "Should find 1 bookmark in other list")
  assert(other_list_bookmarks[1].id == bookmark3_id, "Should find bookmark3")

  -- Test finding bookmarks with non-existent path
  local not_found = repo.find_bookmarks_by_path("/nonexistent/path.lua")
  assert(#not_found == 0, "Should return empty array for non-existent path")
end

-- :lua require("bookmarks.test.repo-test").test_find_lists()
M.test_find_lists = function()
  M.test_setup()

  -- Initially should find no lists (except root)
  local initial_lists = repo.find_lists()
  assert(#initial_lists == 0, "Should start with no lists")

  -- Create multiple test lists
  ---@type Bookmarks.NewNode
  local list1 = {
    type = "list",
    name = "List 1",
    description = "First list",
    children = {},
    created_at = os.time(),
  }
  local list1_id = repo.insert_node(list1)

  ---@type Bookmarks.NewNode
  local list2 = {
    type = "list",
    name = "List 2",
    description = "Second list",
    children = {},
    created_at = os.time(),
  }
  local list2_id = repo.insert_node(list2)

  -- Create a bookmark to ensure it's not included
  ---@type Bookmarks.NewNode
  local bookmark = {
    type = "bookmark",
    name = "Test Bookmark",
    created_at = os.time(),
    children = {},
  }
  repo.insert_node(bookmark)

  -- Test finding all lists
  local found_lists = repo.find_lists()

  -- Verify results
  assert(#found_lists == 2, "Should find exactly two lists")

  -- Sort lists by ID for consistent testing
  table.sort(found_lists, function(a, b)
    return a.id < b.id
  end)

  -- Verify first list
  assert(found_lists[1].id == list1_id, "Should find list1")
  assert(found_lists[1].name == "List 1", "Should have correct name")
  assert(found_lists[1].type == "list", "Should have correct type")
  assert(found_lists[1].description == "First list", "Should have correct description")

  -- Verify second list
  assert(found_lists[2].id == list2_id, "Should find list2")
  assert(found_lists[2].name == "List 2", "Should have correct name")
  assert(found_lists[2].type == "list", "Should have correct type")
  assert(found_lists[2].description == "Second list", "Should have correct description")

  -- Verify root list (id=0) is not included
  for _, list in ipairs(found_lists) do
    assert(list.id ~= 0, "Should not include root list")
  end
end

-- :lua require("bookmarks.test.repo-test").run_all_tests()
M.run_all_tests = function()
  M.test_setup()
  local tests = {
    { name = "test_setup", fn = M.test_setup },
    { name = "test_find_node_not_exist", fn = M.test_find_node_not_exist },
    { name = "test_find_node_exist", fn = M.test_find_node_exist },
    { name = "test_insert_bookmark", fn = M.test_insert_bookmark },
    { name = "test_insert_list", fn = M.test_insert_list },
    { name = "test_update_node_name", fn = M.test_update_node_name },
    { name = "test_delete_node", fn = M.test_delete_node },
    { name = "test_add_to_list", fn = M.test_add_to_list },
    { name = "test_remove_from_list", fn = M.test_remove_from_list },
    { name = "test_get_all_bookmarks", fn = M.test_get_all_bookmarks },
    { name = "test_update_node", fn = M.test_update_node },
    { name = "test_active_list", fn = M.test_active_list },
    { name = "test_active_list_default_root", fn = M.test_active_list_default_root },
    { name = "test_find_node_by_location", fn = M.test_find_node_by_location },
    { name = "test_find_bookmarks_by_path", fn = M.test_find_bookmarks_by_path },
    { name = "test_find_lists", fn = M.test_find_lists },
  }

  print("\nRunning all tests...\n")
  local passed = 0
  local failed = 0
  local failed_tests = {}

  for _, test in ipairs(tests) do
    print(string.format("Running %s...", test.name))
    M.test_setup()

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
