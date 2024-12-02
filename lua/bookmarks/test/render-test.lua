local M = {}
local render = require("bookmarks.tree.render")

---Creates a test tree structure
---@return Bookmarks.Node
local function create_test_tree()
  ---@type Bookmarks.Node
  local root = {
    id = 1,
    name = "Root List",
    type = "list",
    children = {},
    is_expanded = false,
    created_at = os.time(),
  }

  ---@type Bookmarks.Node
  local child_list = {
    id = 2,
    name = "Child List",
    type = "list",
    children = {},
    is_expanded = false,
    created_at = os.time(),
  }

  ---@type Bookmarks.Node
  local bookmark1 = {
    id = 3,
    name = "Bookmark 1",
    type = "bookmark",
    children = {},
    created_at = os.time(),
  }

  ---@type Bookmarks.Node
  local bookmark2 = {
    id = 4,
    name = "Bookmark 2",
    type = "bookmark",
    children = {},
    created_at = os.time(),
  }

  table.insert(root.children, child_list)
  table.insert(child_list.children, bookmark1)
  table.insert(child_list.children, bookmark2)

  return root
end

M.test_render_collapsed_nodes = function()
  local root = create_test_tree()
  -- Both root and child list are already false by default in create_test_tree()

  local lines = {}
  local lines_ctx = {}

  render.render_tree_recursive(root, lines, lines_ctx, 0, root.id)

  -- Should only show the root node since it's collapsed
  assert(#lines == 1, "Should only render root when collapsed")
  assert(lines[1] == "▸ Root List", "Root should show collapsed icon")

  -- Test context
  assert(#lines_ctx == 1, "Should only have context for root")
  assert(lines_ctx[1].id == 1, "Context should be for root")
  assert(lines_ctx[1].deep == 0, "Root should be at depth 0")

  -- Now expand only root and verify
  root.is_expanded = true
  lines = {}
  lines_ctx = {}
  render.render_tree_recursive(root, lines, lines_ctx, 0, root.id)

  assert(#lines == 2, "Should render root and its immediate child")
  assert(lines[1] == "▾ Root List", "Root should show expanded icon")
  assert(lines[2] == "  ▸ Child List", "Child list should be visible but collapsed")
end

M.test_render_tree_recursive = function()
  local root = create_test_tree()
  root.is_expanded = true -- Root must be expanded to see children
  root.children[1].is_expanded = true -- Child list must be expanded to see bookmarks

  local lines = {}
  local lines_ctx = {}

  render.render_tree_recursive(root, lines, lines_ctx, 0, root.id)

  -- Verify lines content
  assert(#lines == 4, "Should have 4 lines rendered")
  assert(lines[1] == "▾ Root List", "Root line should be correct")
  assert(lines[2] == "  ▾ Child List", "Child list line should be correct")
  assert(lines[3] == "    ◉ Bookmark 1", "Bookmark 1 line should be correct")
  assert(lines[4] == "    ◉ Bookmark 2", "Bookmark 2 line should be correct")

  -- Verify lines_ctx content
  assert(#lines_ctx == 4, "Should have 4 line contexts")
  assert(lines_ctx[1].id == 1, "Root id should be correct")
  assert(lines_ctx[1].deep == 0, "Root depth should be 0")
  assert(lines_ctx[1].root_id == 1, "Root's root_id should match")
end

M.test_render_expanded_state = function()
  local root = create_test_tree()
  root.is_expanded = true
  root.children[1].is_expanded = true

  local lines = {}
  local lines_ctx = {}

  render.render_tree_recursive(root, lines, lines_ctx, 0, root.id)

  vim.print(lines)
  vim.print(lines_ctx)
  assert(lines[1] == "▾ Root List", "Expanded root should show expanded icon")
  assert(lines[2] == "  ▾ Child List", "Expanded child should show expanded icon")
end

M.test_render_empty_list = function()
  ---@type Bookmarks.Node
  local empty_list = {
    id = 1,
    name = "Empty List",
    type = "list",
    children = {},
    is_expanded = false,
    created_at = os.time(),
  }

  local lines = {}
  local lines_ctx = {}

  render.render_tree_recursive(empty_list, lines, lines_ctx, 0, empty_list.id)

  assert(#lines == 1, "Should have only one line")
  assert(lines[1] == "▸ Empty List", "Empty list should be rendered correctly")
  assert(#lines_ctx == 1, "Should have only one context")
end

M.test_render_untitled_bookmark = function()
  ---@type Bookmarks.Node
  local untitled = {
    created_at = os.time(),
    id = 1,
    name = "",
    type = "bookmark",
    children = {},
  }

  local lines = {}
  local lines_ctx = {}

  render.render_tree_recursive(untitled, lines, lines_ctx, 0, untitled.id)

  assert(#lines == 1, "Should have one line")
  assert(lines[1] == "◉ [Untitled]", "Untitled bookmark should show placeholder")
end

M.test_render_deep_nesting = function()
  ---@type Bookmarks.Node
  local deep_root = {
    created_at = os.time(),
    id = 1,
    name = "Level 1",
    type = "list",
    children = {
      {
        created_at = os.time(),
        id = 2,
        name = "Level 2",
        type = "list",
        children = {
          {
            created_at = os.time(),
            id = 3,
            name = "Level 3",
            type = "list",
            children = {
              {
                created_at = os.time(),
                id = 4,
                name = "Deep Bookmark",
                type = "bookmark",
                children = {},
              },
            },
            is_expanded = true,
          },
        },
        is_expanded = true,
      },
    },
    is_expanded = true,
  }

  local lines = {}
  local lines_ctx = {}

  render.render_tree_recursive(deep_root, lines, lines_ctx, 0, deep_root.id)

  assert(#lines == 4, "Should render all levels")
  assert(lines[4] == "      ◉ Deep Bookmark", "Should have correct indentation")
  assert(lines_ctx[4].deep == 3, "Should have correct depth in context")
end

-- :lua require("bookmarks.test.render-test").run_all_tests()
M.run_all_tests = function()
  local tests = {
    { name = "test_render_collapsed_nodes", fn = M.test_render_collapsed_nodes },
    { name = "test_render_tree_recursive", fn = M.test_render_tree_recursive },
    { name = "test_render_expanded_state", fn = M.test_render_expanded_state },
    { name = "test_render_empty_list", fn = M.test_render_empty_list },
    { name = "test_render_untitled_bookmark", fn = M.test_render_untitled_bookmark },
    { name = "test_render_deep_nesting", fn = M.test_render_deep_nesting },
  }

  print("\nRunning render tests...\n")
  local passed = 0
  local failed = 0
  local failed_tests = {}

  for _, test in ipairs(tests) do
    print(string.format("Running %s...", test.name))
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
