# luau-thread
Parallel Luau library designed to make parallel luau easier to use (cause the default parallel luau api is shit)

### spawn()

Requires and runs the given module on a separate CPU thread, passing any given
arguments. Returns the id of the spawned thread.

  - **Type**

    ```lua
    function thread.spawn(execute_module: ModuleScript, shared_table: SharedTable, ...): number
    ```
  
  - **Usage**

    ```lua
    local sharedTable = SharedTable.new()
    local runningThreads = {}
    for i = 1, 16 do
    
      table.insert(runningThreads, thread.spawn(execute_module, resultTable, i)
    end
    ```
---

### join()

Yields the calling coroutine until the given thread has finished executing (if it isn't allready finished).

  - **Type**

    ```lua
    function thread.join(thread_id: number)
    ```
  
  - **Usage**

    ```lua
    --Waits for all running threads to finish
    for _, v in runningThreads do
    
      thread.join(v)
    end
    ```
---

### modules

The library takes in modules in place of functions since functions cannot be cross-loaded between Luau VMs, meaning modules must be used in place of functions.

  - **Usage**
  When passing a module through the module must immediately return a function typed as such:
