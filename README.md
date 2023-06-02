# luau-thread
Parallel Luau library designed to make parallel luau easier to use (cause the default parallel luau api is shit)

### spawn()

Requires and runs the given module on a separate CPU thread, passing any given
arguments. Returns the id of the spawned thread.

  - **Type**

    ```lua
    function thread.spawn(execute_module: ModuleScript, ...): number
    ```
  
  - **Usage**

    ```lua
    local sharedTable = SharedTable.new() --Not necessary, but must be used to return any data.
    local runningThreads = {}
    for i = 1, 16 do
    
      table.insert(runningThreads, thread.spawn(execute_module, resultTable, i)
    end
    ```
---

### join()

Yields the calling coroutine until the given thread(s) has finished executing (if it isn't allready finished).

  - **Type**

    ```lua
    function thread.join(thread_id: number | { number })
    ```
  
  - **Usage**

    ```lua
    --Waits for all running threads to finish
    for _, v in runningThreads do
    
      thread.join(v)
    end
    ```
    ```lua
    --Sugar syntax for the previous code block
    thread.join(runningThreads)
    ```
---

### modules

The library takes in modules in place of functions since functions cannot be cross-loaded between Luau VMs, meaning modules must be used in place of functions.

  - **Type**
  
    When passing a module through the module must only return a function as such:
    ```lua
    return function(...)
    end
    ```
---

### SharedTables

If you want to return any data from running parallel code you must use SharedTables;
as regular tables cannot be used to return data, and using regular returns is impossible with the new api.

  - **Type**
    ```lua
    local sharedTable = SharedTable.new()
    local t = thread.spawn(execute_module, sharedTable)
    ```
