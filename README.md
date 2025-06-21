# luau-thread
Parallel Luau library designed to make parallel luau easier to use (cause the default parallel luau api is shit)

### Important performance note

luau-thread uses *BindableEvents* internally, the new default behavior for *BindableEvents* is *"Deferred"*, this means the events wont run immediately, but will run once everything else is done running, this can result in luau-thread taking up to an entire frame to start executing code, and up to another entire frame for your code to return its data, which in most cases is completely unacceptable.

To **fix** this issue, navigate to *workspace*, and set **SignalBehavior** to **Immediate**; This will make events run immediately, meaning all multi-threaded code execution will happen immediately, within the same frame.

Please note that changing *SignalBehavior* may have unintended side effects for the rest of your project, though they should be incredibly easy to work around, as the default *Deferred* behavior can be mimicked using *task.defer()*.

### spawn()

Requires and runs the given module on a separate CPU thread, passing any given
arguments. Returns the id of the spawned thread.

  - **Type**

    ```luau
    function thread.spawn(execute_module: ModuleScript, ...): number
    ```
  
  - **Usage**

    ```luau
    local runningThreads: {number} = {}
    for i = 1, 16 do
    
      table.insert(runningThreads, thread.spawn(ExecuteModule)
    end
    ```
---

### join()

Yields the calling coroutine until the given thread(s) has finished executing (if it isn't already finished).

  - **Type**

    ```luau
    function thread.join(thread_id: number | {number})
    ```
  
  - **Usage**

    ```luau
    -- Waits for all running threads to finish
    for _, v in runningThreads do
    
      thread.join(v)
    end
    ```
    ```luau
    -- Sugar syntax for the previous code block
    thread.join(runningThreads)
    ```
---

### Code execution

New luau-thread users may be confused or put-off by its use of *"function-returning-modules"* instead of passing functions, similarly to the coroutine and task.spawn APIs; This is because functions (or any code for that matter) cannot be sent between Luau VMs, which is what Luau multithreading uses.


To get around this limitation, luau-thread makes use of *"function-returning-modules"*, which are ModuleScripts that return functions, which are then executed in parallel.

Please note that these modules cannot traditionally return any data, if you wish to get any data back to the main thread you will have to use, in best to worst order of performance, *BindableEvents*, *Actor:SendMessage()*, or *SharedTables*

The best way to return data from multiple threads is to use *BindableEvents* to send *buffers* back to the main thread, *buffers* can be moved INCREDIBLY fast, they're many hundreds of times faster than using *Actor:SendMessage()* or *SharedTables*, and are far more memory efficient, their only drawback is that it may be difficult to accurately send incredibly tiny or incredibly large numbers, since they only support up to 32-bit integers, signed integers, and floats.

  - **Usage**
  
    When spawning a thread, the passed module should return only a function, as such:
    ```luau
    -- ExecuteModule.Luau [ModuleScript]
    return function(...)
    
      print("Hello from another thread! I got these overloads:", ...)
    end
    ```
    
    This code sample will: Dispatch *512* threads to run in parallel with some overloads, wait for them all to finish, then print *"Done!"*:
    ```luau
    -- Dispatcher.Luau [Script]
    local runningThreads = {}
    for i = 1, 512 do
    
      table.insert(runningThreads, thread.spawn(ExecuteModule, i, math.random()) -- Overload arguments can be passed.
    end

    thread.join(runningThreads)

    print("Done!")
    ```
---

### SharedTables

If you want to return any data from running parallel code a simple and intuitive option is SharedTables, since luau-thread does not support traditional returns.

  - **Usage**

    The function does not need to only use ... overloads, it can be typed like a normal function, just take care to pass the correct arguments in the dispatcher.
    ```luau
    -- ExecuteModule.Luau [ModuleScript]
    return function(write_table: SharedTable, write_index: number)
      
      write_table[write_index] = `Hello from thread {write_index}!`
    end
    ```
    This code sample will dispatch *512* threads to fill the SharedTable with strings, then it will print the SharedTable, and index *1*
    ```luau
    -- Dispatcher.Luau [Script]
    local sharedTable = SharedTable.new()
    local runningThreads: {number} = {}
    for x = 1, 512 do

      table.insert(runningThreads, thread.spawn(compute_module, sharedTable))
    end
    
    thread.join(runningThreads)
    
    print(sharedTable) -- table full of "Hello World!"
    print(sharedTable[1]) -- "Hello from thread 1!"
    ```

  - **Notes**
    
    It is not recommended to use SharedTables for all but the most simple of tasks;
    
    They have incredibly slow read and write speeds, making them nearly useless for any bulk computation, which can result in multi-threaded code running **much slower** than it would if it was single-threaded.

i was gonna add a section for Actor:SendMessage() but its so slow and so useless and is deferred which adds like 10ms to every operation so im not even gonna bother covering it, you should not be using it at all.
