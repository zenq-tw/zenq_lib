--- File with generic definitions. 
--- You shouldn't require it directly (it doesn't have real code)

---@alias LookupTable<T> { [T]: true }

---@alias WeakValueTable<K, V> {[K]: V}

---@alias TFactory<T> fun(key: any): T
---@alias defaultdict<K, V>  {[K]: V}

---@alias TNonRewritableDict<K, V> {[K]: V}


---@alias AvailableOpenFileMod
---| 'w' open for write (will clear all existed content)
---| 'a' same, but will append to file
