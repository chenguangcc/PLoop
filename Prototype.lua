--===========================================================================--
-- Copyright (c) 2011-2018 WangXH <kurapica125@outlook.com>                  --
--                                                                           --
-- Permission is hereby granted, free of charge, to any person               --
-- obtaining a copy of this software and associated Documentation            --
-- files (the "Software"), to deal in the Software without                   --
-- restriction, including without limitation the rights to use,              --
-- copy, modify, merge, publish, distribute, sublicense, and/or sell         --
-- copies of the Software, and to permit persons to whom the                 --
-- Software is furnished to do so, subject to the following                  --
-- conditions:                                                               --
--                                                                           --
-- The above copyright notice and this permission notice shall be            --
-- included in all copies or substantial portions of the Software.           --
--                                                                           --
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,           --
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES           --
-- OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND                  --
-- NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT               --
-- HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,              --
-- WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING              --
-- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR             --
-- OTHER DEALINGS IN THE SOFTWARE.                                           --
--===========================================================================--

--===========================================================================--
--                                                                           --
--                   Prototype Lua Object-Oriented System                    --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2017/04/02                                               --
-- Update Date  :   2018/01/23                                               --
-- Version      :   1.0.0-alpha.003                                          --
--===========================================================================--

-------------------------------------------------------------------------------
--                                preparation                                --
-------------------------------------------------------------------------------
do
    -----------------------------------------------------------------------
    --                      environment preparation                      --
    -----------------------------------------------------------------------
    local cerror, cformat       = error, string.format
    local _PLoopEnv             = setmetatable(
        {
            _G                  = _G,
            LUA_VERSION         = tonumber(_VERSION and _VERSION:match("[%d%.]+")) or 5.1,

            -- Weak Mode
            WEAK_KEY            = { __mode = "k"  },
            WEAK_VALUE          = { __mode = "v"  },
            WEAK_ALL            = { __mode = "kv" },

            -- Iterator
            ipairs              = ipairs(_G),
            pairs               = pairs (_G),
            next                = next,
            select              = select,

            -- String
            strlen              = string.len,
            strformat           = string.format,
            strfind             = string.find,
            strsub              = string.sub,
            strbyte             = string.byte,
            strchar             = string.char,
            strrep              = string.rep,
            strgsub             = string.gsub,
            strupper            = string.upper,
            strlower            = string.lower,
            strmatch            = string.match,
            strgmatch           = string.gmatch,

            -- Table
            tblconcat           = table.concat,
            tinsert             = table.insert,
            tremove             = table.remove,
            unpack              = table.unpack or unpack,
            sort                = table.sort,
            setmetatable        = setmetatable,
            getmetatable        = getmetatable,
            rawset              = rawset,
            rawget              = rawget,

            -- Type
            type                = type,
            tonumber            = tonumber,
            tostring            = tostring,

            -- Math
            floor               = math.floor,
            mlog                = math.log,
            mabs                = math.abs,

            -- Coroutine
            create              = coroutine.create,
            resume              = coroutine.resume,
            running             = coroutine.running,
            status              = coroutine.status,
            wrap                = coroutine.wrap,
            yield               = coroutine.yield,

            -- Safe
            pcall               = pcall,
            error               = error,
            print               = print,
            newproxy            = newproxy or false,

            -- In lua 5.2, the loadstring is deprecated
            loadstring          = loadstring or load,
            loadfile            = loadfile,

            -- Debug lib
            debug               = debug or false,
            debuginfo           = debug and debug.getinfo or false,
            getupvalue          = debug and debug.getupvalue or false,
            traceback           = debug and debug.traceback or false,
            setfenv             = setfenv or debug and debug.setfenv or false,
            getfenv             = getfenv or debug and debug.getfenv or false,
            collectgarbage      = collectgarbage,

            -- Share API
            fakefunc            = function() end,
        }, {
            __index             = function(self, k) cerror(cformat("Global variable %q can't be found", k), 2) end,
            __metatable         = true,
        }
    )
    if setfenv then setfenv(1, _PLoopEnv) else _ENV = _PLoopEnv end

    -----------------------------------------------------------------------
    -- The table contains several settings can be modified based on the
    -- target platform and frameworks. It must be provided before loading
    -- the PLoop, and the table and its fields are all optional.
    --
    -- @table PLOOP_PLATFORM_SETTINGS
    -----------------------------------------------------------------------
    PLOOP_PLATFORM_SETTINGS     = (function(default)
        local settings = _G.PLOOP_PLATFORM_SETTINGS
        if type(settings) == "table" then
            _G.PLOOP_PLATFORM_SETTINGS = nil

            for k, v in pairs, default do
                local r = settings[k]
                if r ~= nil then
                    if type(r) ~= type(v) then
                        Error("The PLOOP_PLATFORM_SETTINGS[%q]'s value must be %s.", k, type(v))
                    else
                        default[k]  = r
                    end
                end
            end
        end
        return default
    end) {
        --- Whether the attribute system use warning instead of error for
        -- invalid attribute target type.
        -- Default false
        -- @owner       PLOOP_PLATFORM_SETTINGS
        ATTR_USE_WARN_INSTEAD_ERROR         = false,

        --- Whether the environmet allow global variable be nil, if false,
        -- things like ture(spell error) could trigger error.
        -- Default true
        -- @owner       PLOOP_PLATFORM_SETTINGS
        ENV_ALLOW_GLOBAL_VAR_BE_NIL         = true,

        --- Whether all enumerations are case ignored.
        -- Default false
        -- @owner       PLOOP_PLATFORM_SETTINGS
        ENUM_GLOBAL_IGNORE_CASE             = false,

        --- Whether allow old style of type definitions like :
        --      class "A"
        --          -- xxx
        --      endclass "A"
        --
        -- Default false
        -- @owner       PLOOP_PLATFORM_SETTINGS
        TYPE_DEFINITION_WITH_OLD_STYLE      = false,

        --- Whether all old objects keep using new features when their
        -- classes or extend interfaces are re-defined.
        -- Default false
        -- @owner       PLOOP_PLATFORM_SETTINGS
        CLASS_ALL_SIMPLE_VERSION            = false,

        --- Whether all interfaces & classes only use the classic format
        -- `Super.Method(obj, ...)` to call super's features, don't use new
        -- style like :
        --      Super[obj].Name = "Ann"
        --      Super[obj].OnNameChanged = Super[obj].OnNameChanged + print
        --      Super[obj]:Greet("King")
        -- Default false
        -- @owner       PLOOP_PLATFORM_SETTINGS
        CLASS_ALL_OLD_SUPER_STYLE           = false,

        --- The Log level used in the Prototype core part.
        --          1 : Trace
        --          2 : Debug
        --          3 : Info
        --          4 : Warn
        --          5 : Error
        --          6 : Fatal
        -- Default 3(Info)
        -- @owner       PLOOP_PLATFORM_SETTINGS
        CORE_LOG_LEVEL                      = 3,

        --- The core log handler works like :
        --      function CORE_LOG_HANDLER(message, loglevel)
        --          -- message  : the log message
        --          -- loglevel : the log message's level
        --      end
        -- Default print
        -- @owner       PLOOP_PLATFORM_SETTINGS
        CORE_LOG_HANDLER                    = print,

        --- Whether the system is used in a platform where multi os threads
        -- share one lua-state, so the access conflict can't be ignore.
        -- Default false
        -- @owner       PLOOP_PLATFORM_SETTINGS
        MULTI_OS_THREAD                     = false,

        --- Whether the system is used in a platform where multi os threads
        -- share one lua-state, and the lua_lock and lua_unlock apis are
        -- applied, so PLoop don't need to care about the thread conflict.
        -- Default false
        -- @owner       PLOOP_PLATFORM_SETTINGS
        MULTI_OS_THREAD_LUA_LOCK_APPLIED    = false,

        --- Whether the system send warning messages when the system is used
        -- in a platform where multi os threads share one lua-state, and
        -- global variables are saved not to the environment but an inner
        -- cache, it'd solve the thread conflict, but the environment need
        -- fetch them by __index meta-call, so it's better to declare local
        -- variables to hold them for best access speed.
        -- Default true
        -- @owner       PLOOP_PLATFORM_SETTINGS
        MULTI_OS_THREAD_ENV_AUTO_CACHE_WARN = true,
    }

    -----------------------------------------------------------------------
    --                               share                               --
    -----------------------------------------------------------------------
    strtrim                     = function (s)    return s and strgsub(s, "^%s*(.-)%s*$", "%1") or "" end

    typeconcat                  = function (a, b) return tostring(a) .. tostring(b) end
    wipe                        = function (t)    for k in pairs, t do t[k] = nil end return t end

    readOnly                    = function (self) error(strformat("The %s can't be written", tostring(self)), 2) end
    writeOnly                   = function (self) error(strformat("The %s can't be read",    tostring(self)), 2) end

    newStorage                  = PLOOP_PLATFORM_SETTINGS.MULTI_OS_THREAD and function() return {} end or function(weak) return setmetatable({}, weak) end
    saveStorage                 = PLOOP_PLATFORM_SETTINGS.MULTI_OS_THREAD and function(self, key, value)
                                        local new
                                        if value == nil then
                                            if self[key] == nil then return end
                                            new  = {}
                                        else
                                            if self[key] ~= nil then self[key] = value return self end
                                            new  = { [key] = value }
                                        end
                                        for k, v in pairs, self do if k ~= key then new[k] = v end end
                                        return new
                                    end
                                    or  function(self, key, value) self[key] = value return self end
    safesetfenv                 = PLOOP_PLATFORM_SETTINGS.TYPE_DEFINITION_WITH_OLD_STYLE and setfenv or fakefunc

    -----------------------------------------------------------------------
    --                               debug                               --
    -----------------------------------------------------------------------
    getCallLine                 = not debuginfo and fakefunc or function (stack)
        local info = debuginfo((stack or 2) + 1, "lS")
        if info then
            return "@" .. (info.short_src or "unknown") .. ":" .. (info.currentline or "?")
        end
    end

    -----------------------------------------------------------------------
    --                               clone                               --
    -----------------------------------------------------------------------
    deepClone                   = function (src, tar, override, cache)
        if cache then cache[src] = tar end

        for k, v in pairs, src do
            if override or tar[k] == nil then
                if type(v) == "table" and getmetatable(v) == nil then
                    tar[k] = cache and cache[v] or deepClone(v, {}, override, cache)
                else
                    tar[k] = v
                end
            elseif type(v) == "table" and type(tar[k]) == "table" and getmetatable(v) == nil and getmetatable(tar[k]) == nil then
                deepClone(v, tar[k], override, cache)
            end
        end
        return tar
    end

    tblclone                    = function (src, tar, deep, override, safe)
        if src then
            if deep then
                local cache = safe and _Cache()
                deepClone(src, tar, override, cache)   -- no cache for duplicated table
                if safe then _Cache(cache) end
            else
                for k, v in pairs, src do
                    if override or tar[k] == nil then tar[k] = v end
                end
            end
        end
        return tar
    end

    clone                       = function (src, deep, safe)
        if type(src) == "table" and getmetatable(src) == nil then
            return tblclone(src, {}, deep, true, safe)
        else
            return src
        end
    end

    -----------------------------------------------------------------------
    --                          loading snippet                          --
    -----------------------------------------------------------------------
    if LUA_VERSION > 5.1 then
        loadSnippet             = function (chunk, source, env)
            Debug("[core][loadSnippet] ==> %s ....", source or "anonymous")
            Trace(chunk)
            Trace("[core][loadSnippet] <== %s", source or "anonymous")
            return loadstring(chunk, source, nil, env or _PLoopEnv)
        end
    else
        loadSnippet             = function (chunk, source, env)
            Debug("[core][loadSnippet] ==> %s ....", source or "anonymous")
            Trace(chunk)
            Trace("[core][loadSnippet] <== %s", source or "anonymous")
            local v, err = loadstring(chunk, source)
            if v then setfenv(v, env or _PLoopEnv) end
            return v, err
        end
    end

    -----------------------------------------------------------------------
    --                         flags management                          --
    -----------------------------------------------------------------------
    if LUA_VERSION >= 5.3 then
        validateFlags           = loadstring [[
            return function(checkValue, targetValue)
                return (checkValue & (targetValue or 0)) > 0
            end
        ]] ()

        turnOnFlags             = loadstring [[
            return function(checkValue, targetValue)
                return checkValue | (targetValue or 0)
            end
        ]] ()

        turnOffFlags            = loadstring [[
            return function(checkValue, targetValue)
                return (~checkValue) & (targetValue or 0)
            end
        ]] ()
    elseif (LUA_VERSION == 5.2 and type(_G.bit32) == "table") or (LUA_VERSION == 5.1 and type(_G.bit) == "table") then
        local band              = _G.bit32 and bit32.band or bit.band
        local bor               = _G.bit32 and bit32.bor  or bit.bor
        local bnot              = _G.bit32 and bit32.bnot or bit.bnot

        validateFlags           = function (checkValue, targetValue)
            return band(checkValue, targetValue or 0) > 0
        end

        turnOnFlags             = function (checkValue, targetValue)
            return bor(checkValue, targetValue or 0)
        end

        turnOffFlags            = function (checkValue, targetValue)
            return band(bnot(checkValue), targetValue or 0)
        end
    else
        validateFlags           = function (checkValue, targetValue)
            if not targetValue or checkValue > targetValue then return false end
            targetValue = targetValue % (2 * checkValue)
            return (targetValue - targetValue % checkValue) == checkValue
        end

        turnOnFlags             = function (checkValue, targetValue)
            if not validateFlags(checkValue, targetValue) then
                return checkValue + (targetValue or 0)
            end
            return targetValue
        end

        turnOffFlags            = function (checkValue, targetValue)
            if validateFlags(checkValue, targetValue) then
                return targetValue - checkValue
            end
            return targetValue
        end
    end

    -----------------------------------------------------------------------
    --                             newproxy                              --
    -----------------------------------------------------------------------
    newproxy                    = newproxy or (function ()
        local falseMeta         = { __metatable = false }
        local proxymap          = newStorage(WEAK_ALL)

        return function (prototype)
            if prototype == true then
                local meta  = {}
                prototype   = setmetatable({}, meta)
                proxymap[prototype] = meta
                return prototype
            elseif proxymap[prototype] then
                return setmetatable({}, proxymap[prototype])
            else
                return setmetatable({}, falseMeta)
            end
        end
    end)()

    -----------------------------------------------------------------------
    --                        environment control                        --
    -----------------------------------------------------------------------
    if not setfenv then
        if debug and debug.getinfo and debug.getupvalue and debug.upvaluejoin and debug.getlocal then
            local getinfo       = debug.getinfo
            local getupvalue    = debug.getupvalue
            local upvaluejoin   = debug.upvaluejoin
            local getlocal      = debug.getlocal

            setfenv             = function (f, t)
                f = type(f) == 'function' and f or getinfo(f + 1, 'f').func
                local up, name = 0
                repeat
                    up = up + 1
                    name = getupvalue(f, up)
                until name == '_ENV' or name == nil
                if name then upvaluejoin(f, up, function() return t end, 1) end
            end

            getfenv             = function (f)
                local cf, up, name, val = type(f) == 'function' and f or getinfo(f + 1, 'f').func, 0
                repeat
                    up = up + 1
                    name, val = getupvalue(cf, up)
                until name == '_ENV' or name == nil
                if val then return val end

                if type(f) == "number" then
                    f, up = f + 1, 0
                    repeat
                        up = up + 1
                        name, val = getlocal(f, up)
                    until name == '_ENV' or name == nil
                    if val then return val end
                end
            end
        else
            getfenv             = fakefunc
            setfenv             = fakefunc
        end
    end

    -----------------------------------------------------------------------
    --                            main cache                             --
    -----------------------------------------------------------------------
    _Cache                      = setmetatable({}, {
        __call                  = PLOOP_PLATFORM_SETTINGS.MULTI_OS_THREAD and
            function(self, tbl) return tbl and wipe(tbl) or {} end
            or
            function(self, tbl) if tbl then return tinsert(self, wipe(tbl)) else return tremove(self) or {} end end,
        }
    )

    -----------------------------------------------------------------------
    --                                log                                --
    -----------------------------------------------------------------------
    local generateLogger        = function (prefix, loglvl)
        local handler = PLOOP_PLATFORM_SETTINGS.CORE_LOG_HANDLER
        return PLOOP_PLATFORM_SETTINGS.CORE_LOG_LEVEL > loglvl and fakefunc or
            function(msg, stack, ...)
                if type(stack) == "number" then
                    msg = prefix .. strformat(msg, ...) .. (getCallLine(stack + 1) or "")
                elseif stack then
                    msg = prefix .. strformat(msg, stack, ...)
                else
                    msg = prefix .. msg
                end
                return handler(msg, loglvl)
            end
    end

    Trace                       = generateLogger("[PLoop:Trace]", 1)
    Debug                       = generateLogger("[PLoop:Debug]", 2)
    Info                        = generateLogger("[PLoop: Info]", 3)
    Warn                        = generateLogger("[PLoop: Warn]", 4)
    Error                       = generateLogger("[PLoop:Error]", 5)
    Fatal                       = generateLogger("[PLoop:Fatal]", 6)

    -----------------------------------------------------------------------
    --                          keyword helper                           --
    -----------------------------------------------------------------------
    local parseParams           = function (ptype, ...)
        local visitor           = ptype and environment.GetKeywordVisitor(ptype)
        local env, target, definition, flag, stack

        for i = 1, select('#', ...) do
            local v = select(i, ...)
            local t = type(v)

            if t == "boolean" then
                if flag == nil then flag = v end
            elseif t == "number" then
                stack = stack or v
            elseif t == "function" then
                definition = definition or v
            elseif t == "string" then
                v       = strtrim(v)
                if strfind(v, "^%S+$") then
                    target      = target or v
                else
                    definition  = definition or v
                end
            elseif t == "userdata" then
                if ptype and ptype.Validate(v) then
                    target      = target or v
                end
            elseif t == "table" then
                if getmetatable(v) ~= nil then
                    if ptype and ptype.Validate(v) then
                        target  = target or v
                    else
                        env     = env or v
                    end
                elseif v == _G then
                    env         = env or v
                else
                    definition  = definition or v
                end
            end
        end

        -- Default
        stack = stack or 1
        env = env or visitor or getfenv(stack + 3) or _G

        return visitor, env, target, definition, flag, stack
    end

    -- Used for features like property, event, member and namespace
    GetFeatureParams            = function (ftype, ...)
        local  visitor, env, target, definition, flag, stack = parseParams(ftype, ...)
        return visitor, env, target, definition, flag, stack
    end

    -- Used for types like enum, struct, class and interface : class([env,][name,][definition,][keepenv,][stack])
    GetTypeParams               = function (nType, ptype, ...)
        local  visitor, env, target, definition, flag, stack = parseParams(nType, ...)

        if target then
            if type(target) == "string" then
                local path  = target
                target      = namespace.GetNameSpace(environment.GetNameSpace(visitor or env), path)
                if not target then
                    target  = prototype.NewProxy(ptype)
                    namespace.SaveNameSpace(environment.GetNameSpace(visitor or env), path, target, stack + 2)
                end

                if not nType.Validate(target) then
                    target  = nil
                else
                    if visitor then rawset(visitor, namespace.GetNameSpaceName(target, true), target) end
                    if env and env ~= visitor then rawset(env, namespace.GetNameSpaceName(target, true), target) end
                end
            end
        else
            -- Anonymous
            target = prototype.NewProxy(ptype)
            namespace.SaveAnonymousNameSpace(target)
        end

        return visitor, env, target, definition, flag, stack
    end

    ParseDefinition             = function(definition, env, stack)
        if type(definition) == "string" then
            local def, msg  = loadSnippet("return function(_ENV)\n" .. definition .. "\nend", nil, env)
            if def then
                def, msg    = pcall(def)
                if def then
                    definition = msg
                else
                    error(msg, (stack or 1) + 1)
                end
            else
                error(msg, (stack or 1) + 1)
            end
        end
        return definition
    end
end

-------------------------------------------------------------------------------
-- The prototypes are types of other types(like classes), for a class "A",
-- A is its object's type and the class is A's prototype.
--
-- The prototypes are simple userdata generated like:
--
--      proxy = prototype {
--          __index = function(self, key) return rawget(self, "__" .. key) end,
--          __newindex = function(self, key, value)
--              rawset(self, "__" .. key, value)
--          end,
--      }
--
--      obj = prototype.NewObject(proxy)
--      obj.Name = "Test"
--      print(obj.Name, obj.__Name)
--
-- The prototypes are normally userdata created by newproxy if the newproxy API
-- existed, otherwise a fake newproxy will be used and they will be tables.
--
-- All meta-table settings will be copied to the result's meta-table, and there
-- are two fields whose default value is provided by the prototype system :
--      * __metatable : if nil, the prototype itself would be used.
--      * __tostring  : if its value is string, it'll be converted to a function
--              that return the value, if the prototype name is provided and the
--              __tostring is nil, the name would be used.
--
-- The prototype system also support a simple inheritance system like :
--
--      cproxy = prototype (proxy, {
--          __call = function(self, ...) end,
--      })
--
-- The new prototype's meta-table will copy meta-settings from its super except
-- the __metatable.
--
-- The complete definition syntaxes are
--
--      val = prototype ([name][super,]definiton[,nodeepclone][,stack])
--
-- The params :
--      * name          : string, the prototype's name, it'd be used in the
--              __tostring, if it's not provided.
--
--      * super         : prototype, the super prototype whose meta-settings
--              would be copied to the new one.
--
--      * definition    : table, the prototype's meta-settings.
--
--      * nodeepclone   : boolean, the __index maybe a table, normally, it's
--              content would be deep cloned to the prototype's meta-settings,
--              if true, the __index table will be used directly, so you may
--              modify it after the prototype's definition.
--
--      * stack         : number, the stack level used to raise errors.
--
-- @prototype   prototype
-------------------------------------------------------------------------------
do
    -----------------------------------------------------------------------
    --                          private storage                          --
    -----------------------------------------------------------------------
    local _Prototype            = newStorage(WEAK_ALL)

    -----------------------------------------------------------------------
    --                          private helpers                          --
    -----------------------------------------------------------------------
    local savePrototype         = function (meta, super, nodeepclone, stack)
        local name
        local prototype         = newproxy(true)
        local pmeta             = getmetatable(prototype)
        _Prototype              = saveStorage(_Prototype, prototype, pmeta)

        -- Default
        if meta                                 then tblclone(meta, pmeta,  not nodeepclone, true) end
        if pmeta.__metatable        == nil      then pmeta.__metatable      = prototype end
        if type(pmeta.__tostring)   == "string" then name, pmeta.__tostring = pmeta.__tostring, nil end
        if pmeta.__tostring         == nil      then pmeta.__tostring       = name and function() return name end end

        -- Inherit
        if super                                then tblclone(_Prototype[super], pmeta, true, false) end

        Debug("[prototype] %s created", (stack or 1) + 1, name or "anonymous")

        return prototype
    end

    -----------------------------------------------------------------------
    --                             prototype                             --
    -----------------------------------------------------------------------
    prototype                   = savePrototype {
        __tostring              = "prototype",
        __index                 = {
            --- Get the methods of the prototype
            -- @static
            -- @method  GetMethods
            -- @owner   prototype
            -- @format  (prototype[, cache])
            -- @param   prototype               the target prototype
            -- @param   cache:(table|boolean)   whether save the result in the cache if it's a table or return a cache table if it's true
            -- @rformat (iter, prototype)       without the cache parameter, used in generic for
            -- @return  iter:function           the iterator
            -- @return  prototype               the prototype itself
            -- @rformat (cache)                 with the cache parameter, return the cache of the methods.
            -- @return  cache
            -- @usage   for name, func in prototype.GetMethods(class) do print(name) end
            -- @usage   for name, func in pairs(prototype.GetMethods(class, true)) do print(name) end
            ["GetMethods"]      = function(self, cache)
                local meta      = _Prototype[self]
                if meta and type(meta.__index) == "table" then
                    local methods = meta.__index
                    if cache then
                        cache   = type(cache) == "table" and wipe(cache) or {}
                        for k, v in pairs, methods do if type(v) == "function" then cache[k] = v end end
                        return cache
                    else
                        return function(self, n)
                            local k, v = next(methods, n)
                            while k and type(v) ~= "function" do k, v = next(methods, k) end
                            return k, v
                        end, self
                    end
                elseif cache then
                    return type(cache) == "table" and cache or nil
                else
                    return fakefunc, self
                end
            end,

            --- Create a proxy with the prototype's meta-table
            -- @static
            -- @method  NewProxy
            -- @owner   prototype
            -- @param   prototype               the target prototype
            -- @return  proxy:userdata          the proxy of the same meta-table
            -- @usage   clsA = prototype.NewProxy(class)
            ["NewProxy"]        = newproxy,

            --- Create a table(object) with the prototype's meta-table
            -- @static
            -- @method  NewObject
            -- @owner   prototype
            -- @format  (prototype, [object])
            -- @param   prototype               the target prototype
            -- @param   object:table            the raw-table used to be set the prototype's metatable
            -- @return  object:table            the table with the prototype's meta-table
            ["NewObject"]       = function(self, tbl) return setmetatable(type(tbl) == "table" and tbl or {}, _Prototype[self]) end,

            --- Whether the value is an object(proxy) of the prototype(has the same meta-table),
            -- only works for the prototype that use itself as the __metatable.
            -- @static
            -- @method  ValidateValue
            -- @owner   prototype
            -- @param   prototype               the target prototype
            -- @param   value:(table|userdata)  the value to be validated
            -- @return  result:boolean          true if the value is generated from the prototype
            ["ValidateValue"]   = function(self, val) return getmetatable(val) == self end,

            --- Whether the value is a prototype
            -- @static
            -- @method  Validate
            -- @owner   prototype
            -- @param   prototype               the prototype to be validated
            -- @return  result:boolean          true if the prototype is valid
            ["Validate"]        = function(self) return _Prototype[self] and self or nil end,
        },
        __newindex              = readOnly,
        __call                  = function (self, ...)
            local meta, super, nodeepclone, stack

            for i = 1, select("#", ...) do
                local value         = select(i, ...)
                local vtype         = type(value)

                if vtype == "boolean" then
                    nodeepclone     = value
                elseif vtype == "number" then
                    stack           = value
                elseif vtype == "table" then
                    if getmetatable(value) == nil then
                        meta        = value
                    elseif _Prototype[value] then
                        super       = value
                    end
                elseif vtype == "userdata" and _Prototype[value] then
                    super           = value
                end
            end

            local prototype         = savePrototype(meta, super, nodeepclone, (stack or 1) + 1)
            return prototype
        end,
    }
end

-------------------------------------------------------------------------------
-- The attributes are used to bind informations to features, or used to modify
-- those features directly.
--
-- The attributes should provide attribute usages by themselves or their types.
--
-- The attribute usages are fixed name fields, methods or properties of the
-- attribute:
--
--      * InitDefinition    A method used to modify the target's definition or
--                      init the target before it load its definition, and its
--                      return value will be used as the new definition for the
--                      target if existed.
--          * Parameters :
--              * attribute     the attribute
--              * target        the target like class, method and etc
--              * targetType    the target type, that's a flag value registered
--                      by types. @see attribute.RegisterTargetType
--              * definition    the definition of the target.
--              * owner         the target's owner, it the target is a method,
--                      the owner may be a class or interface that contains it.
--              * name          the target's name, like method name.
--          * Returns :
--              * (definiton)   the return value will be used as the target's
--                      new definition.
--
--      * ApplyAttribute    A method used to apply the attribute to the target.
--                      the method would be called after the definition of the
--                      target. The target still can be modified.
--          * Parameters :
--              * attribute     the attribute
--              * target        the target like class, method and etc
--              * targetType    the target type, that's a flag value registered
--                      by the target type. @see attribute.RegisterTargetType
--              * owner         the target's owner, it the target is a method,
--                      the owner may be a class or interface that contains it.
--              * name          the target's name, like method name.
--
--      * AttachAttribute   A method used to generate attachment to the target
--                      such as runtime document, map to database's tables and
--                      etc. The method would be called after the definition of
--                      the target. The target can't be modified.
--          * Parameters :
--              * attribute     the attribute
--              * target        the target like class, method and etc
--              * targetType    the target type, that's a flag value registered
--                      by the target type. @see attribute.RegisterTargetType
--              * owner         the target's owner, it the target is a method,
--                      the owner may be a class or interface that contains it.
--              * name          the target's name, like method name.
--          * Returns :
--              * (attach)      the return value will be used as attachment of
--                      the attribute's type for the target.
--
--      * AttributeTarget   Default 0 (all types). The flags that represents
--              the type of the target like class, method and other features.
--
--      * Inheritable       Default false. Whether the attribute is inheritable
--              , @see attribute.ApplyAttributes
--
--      * Overridable       Default true. Whether the attribute's saved data is
--              overridable.
--
--      * Priority          Default 0. The attribute's priority, the bigger the
--              first to be applied.
--
--      * SubLevel          Default 0. The priority's sublevel, for attributes
--              with same priority, the bigger sublevel the first be applied.
--
--      * Final             Default false. Special for attribute's type, so the
--              type's attribute usage can't be overridden, that's means the
--              attribute type can't be registered again.
--
-- To fetch the attribute usages from an attribute, take the *ApplyAttribute*
-- as an example, the system will first use `attr["ApplyAttribute"]` to fetch
-- the value, since the system don't care how it's provided, field, property,
-- __index all works.
--
-- If it's nil, the system will use `getmetatable(attr)` to get its type, the
-- type may be registered to the attribute system with the attribute usages,
-- if it existed, the system will try to fetch the value from it.
-- @see attribute.RegisterAttributeType
--
-- If the attribute don't provide attribute usage and so it's type, the default
-- value will be used.
--
-- Although the attribute system is designed without the type requirement, it's
-- better to define them by creating classes extend @see System.IAttribute
--
-- To use the attribute system on a target within its definition, here is list
-- of actions:
--
--   1. Save attributes to the target.         @see attribute.SaveAttributes
--   2. Inherit super attributes to the target.@see attribute.InheritAttributes
--   3. Modify the definition of the target.   @see attribute.InitDefinition
--   4. Change the target if needed.           @see attribute.ToggleTarget
--   5. Apply the definition on the target.
--   6. Apply the attributes on the target.    @see attribute.ApplyAttributes
--   7. Finish the definition of the target.
--   8. Attach attributes datas to the target. @see attribute.AttachAttributes
--
-- The step 2 can be processed after step 3 since we can't know the target's
-- super before it's definition, but in that case, the inherited attributes
-- can't modify the target's definition.
--
-- The step 2, 3, 4, 6 are all optional.
--
-- @prototype   attribute
-------------------------------------------------------------------------------
do
    -----------------------------------------------------------------------
    --                          public constants                         --
    -----------------------------------------------------------------------
    -- ATTRIBUTE TARGETS
    ATTRTAR_ALL                 = 0

    -----------------------------------------------------------------------
    --                          private storage                          --
    -----------------------------------------------------------------------
    -- Attribute Data
    local _AttrTargetTypes      = { [ATTRTAR_ALL] = "All" }

    -- Attribute Target Data
    local _AttrTargetData       = newStorage(WEAK_KEY)
    local _AttrTargetInrt       = newStorage(WEAK_KEY)

    -- Temporary Cache
    local _RegisteredAttrs      = {}
    local _RegisteredAttrsStack = {}
    local _TargetAttrs          = newStorage(WEAK_KEY)

    -----------------------------------------------------------------------
    --                          private helpers                          --
    -----------------------------------------------------------------------
    local _UseWarnInstreadErr   = PLOOP_PLATFORM_SETTINGS.ATTR_USE_WARN_INSTEAD_ERROR

    local getAttributeUsage     = function (attr)
        local info  = _AttrTargetData[getmetatable(attr)]
        return info and info[attribute]
    end

    local getAttrUsageField     = function (obj, field, default, chkType)
        local val   = obj and obj[field]
        if val ~= nil and (not chkType or type(val) == chkType) then return val end
        return default
    end

    local getAttributeInfo      = function (attr, field, default, chkType, attrusage)
        local val   = getAttrUsageField(attr, field, nil, chkType)
        if val == nil then val  = getAttrUsageField(attrusage or getAttributeUsage(attr), field, nil, chkType) end
        if val ~= nil then return val end
        return default
    end

    local addAttribute          = function (list, attr, noSameType)
        for _, v in ipairs, list, 0 do
            if v == attr then return end
            if noSameType and getmetatable(v) == getmetatable(attr) then return end
        end

        local idx       = 1
        local priority  = getAttributeInfo(attr, "Priority", 0, "number")
        local sublevel  = getAttributeInfo(attr, "SubLevel", 0, "number")

        while list[idx] do
            local patr  = list[idx]
            local pprty = getAttributeInfo(patr, "Priority", 0, "number")
            local psubl = getAttributeInfo(patr, "SubLevel", 0, "number")

            if priority > pprty or (priority == pprty and sublevel > psubl) then break end
            idx = idx + 1
        end

        tinsert(list, idx, attr)
    end

    -----------------------------------------------------------------------
    --                             prototype                             --
    -----------------------------------------------------------------------
    attribute                   = prototype {
        __tostring              = "attribute",
        __index                 = {
            --- Use the registered attributes to init the target's definition
            -- @static
            -- @method  InitDefinition
            -- @owner   attribute
            -- @format  (target, targetType, definition, [owner], [name][, ...])
            -- @param   target          the target, maybe class, method, object and etc
            -- @param   targetType      the flag value of the target's type
            -- @param   definition      the definition of the target
            -- @param   owner           the target's owner, like the class for a method
            -- @param   name            the target's name if it has owner
            -- @return  definition      the target's new definition, nil means no change, false means cancel the target's definition, it may be done by the attribute, these may not be supported by the target type
            ["InitDefinition"]  = function(target, targetType, definition, owner, name)
                local tarAttrs  = _TargetAttrs[target]
                if not tarAttrs then return definition end

                -- Apply the attribute to the target
                Debug("[attribute][InitDefinition] ==> [%s]%s", _AttrTargetTypes[targetType] or "Unknown", owner and ("[" .. tostring(owner) .. "]" .. name) or tostring(target))

                for i, attr in ipairs, tarAttrs, 0 do
                    local ausage= getAttributeUsage(attr)
                    local apply = getAttributeInfo (attr, "InitDefinition", nil, "function", ausage)

                    -- Apply attribute before the definition
                    if apply then
                        Trace("Call %s.InitDefinition", tostring(attr))

                        local ret = apply(attr, target, targetType, definition, owner, name)
                        if ret ~= nil then definition = ret end
                    end
                end

                Trace("[attribute][InitDefinition] <== [%s]%s", _AttrTargetTypes[targetType] or "Unknown", owner and ("[" .. tostring(owner) .. "]" .. name) or tostring(target))

                return definition
            end;

            --- Apply the registered attributes to the target before the definition
            -- @static
            -- @method  ApplyAttributes
            -- @owner   attribute
            -- @format  (target, targetType, definition, [owner], [name][, ...])
            -- @param   target          the target, maybe class, method, object and etc
            -- @param   targetType      the flag value of the target's type
            -- @param   owner           the target's owner, like the class for a method
            -- @param   name            the target's name if it has owner
            ["ApplyAttributes"] = function(target, targetType, owner, name)
                local tarAttrs  = _TargetAttrs[target]
                if not tarAttrs then return end

                -- Apply the attribute to the target
                Debug("[attribute][ApplyAttributes] ==> [%s]%s", _AttrTargetTypes[targetType] or "Unknown", owner and ("[" .. tostring(owner) .. "]" .. name) or tostring(target))

                for i, attr in ipairs, tarAttrs, 0 do
                    local ausage= getAttributeUsage(attr)
                    local apply = getAttributeInfo (attr, "ApplyAttribute", nil, "function", ausage)

                    -- Apply attribute before the definition
                    if apply then
                        Trace("Call %s.ApplyAttribute", tostring(attr))
                        apply(attr, target, targetType, owner, name)
                    end
                end

                Trace("[attribute][ApplyAttributes] <== [%s]%s", _AttrTargetTypes[targetType] or "Unknown", owner and ("[" .. tostring(owner) .. "]" .. name) or tostring(target))
            end;

            --- Attach the registered attributes data to the target after the definition
            -- @static
            -- @method  AttachAttributes
            -- @owner   attribute
            -- @format  (target, targetType, [owner], [name])
            -- @param   target          the target, maybe class, method, object and etc
            -- @param   targetType      the flag value of the target's type
            -- @param   owner           the target's owner, like the class for a method
            -- @param   name            the target's name if it has owner
            ["AttachAttributes"]= function(target, targetType, owner, name)
                local tarAttrs  = _TargetAttrs[target]
                if not tarAttrs then return else _TargetAttrs[target] = nil end

                local extAttrs  = _AttrTargetData[target] and tblclone(_AttrTargetData[target], _Cache())
                local extInhrt  = _AttrTargetInrt[target] and tblclone(_AttrTargetInrt[target], _Cache())
                local newAttrs  = false
                local newInhrt  = false

                -- Apply the attribute to the target
                Debug("[attribute][AttachAttributes] ==> [%s]%s", _AttrTargetTypes[targetType] or "Unknown", owner and ("[" .. tostring(owner) .. "]" .. name) or tostring(target))

                for i, attr in ipairs, tarAttrs, 0 do
                    local aType = getmetatable(attr)
                    local ausage= getAttributeUsage(attr)
                    local attach= getAttributeInfo (attr, "AttachAttribute",nil,    "function", ausage)
                    local ovrd  = getAttributeInfo (attr, "Overridable",    true,   nil,        ausage)
                    local inhr  = getAttributeInfo (attr, "Inheritable",    false,  nil,        ausage)

                    -- Try attach the attribute
                    if attach and (ovrd or extAttrs == nil or extAttrs[aType] == nil) then
                        Trace("Call %s.AttachAttribute", tostring(attr))

                        local ret = attach(attr, target, targetType, owner, name)

                        if ret ~= nil then
                            extAttrs        = extAttrs or _Cache()
                            extAttrs[aType] = ret
                            newAttrs        = true
                        end
                    end

                    if inhr then
                        Trace("Save inheritable attribute %s", tostring(attr))

                        extInhrt        = extInhrt or _Cache()
                        extInhrt[aType] = attr
                        newInhrt        = true
                    end
                end

                Trace("[attribute][AttachAttributes] <== [%s]%s", _AttrTargetTypes[targetType] or "Unknown", owner and ("[" .. tostring(owner) .. "]" .. name) or tostring(target))

                _Cache(tarAttrs)

                -- Save
                if newAttrs then
                    _AttrTargetData = saveStorage(_AttrTargetData, target, extAttrs)
                elseif extAttrs then
                    _Cache(extAttrs)
                end
                if newInhrt then
                    _AttrTargetInrt = saveStorage(_AttrTargetInrt, target, extInhrt)
                elseif extInhrt then
                    _Cache(extInhrt)
                end
            end;

            --- Get the attached attribute data of the target
            -- @static
            -- @method  GetAttachedData
            -- @owner   attribute
            -- @param   target          the target
            -- @param   attributeType   the attribute type
            ["GetAttachedData"] = function(target, aType)
                local info      = _AttrTargetData[target]
                return info and clone(info[aType], true, true)
            end;

            --- Call a definition function within a standalone attribute system
            -- so it won't use the registered attributes that belong to others.
            -- Normally used in attribute's ApplyAttribute or AttachAttribute
            -- that need create new features with attributes.
            -- @static
            -- @method  IndependentCall
            -- @owner   attribtue
            -- @param   definition      the function to be processed
            ["IndependentCall"] = function(definition)
                if type(definition) ~= "function" then
                    error("Usage : attribute.Register(definition) - the definition must be a function", 2)
                end

                tinsert(_RegisteredAttrsStack, _RegisteredAttrs)
                _RegisteredAttrs= _Cache()

                local ok, msg   = pcall(definition)

                _RegisteredAttrs= tremove(_RegisteredAttrsStack) or _Cache()

                if not ok then error(msg, 0) end
            end;

            --- Register the super's inheritable attributes to the target, must be called after
            -- the @attribute.SaveAttributes and before the @attribute.AttachAttributes
            -- @static
            -- @method  Inherit
            -- @owner   attribute
            -- @format  (target, targetType, ...)
            -- @param   target          the target, maybe class, method, object and etc
            -- @param   targetType      the flag value of the target's type
            -- @param   ...             the target's super that used for attribute inheritance
            ["InheritAttributes"] = function(target, targetType, ...)
                local cnt       = select("#", ...)
                if cnt == 0 then return end

                -- Apply the attribute to the target
                Debug("[attribute][InheritAttributes] ==> [%s]%s", _AttrTargetTypes[targetType] or "Unknown", tostring(target))

                local tarAttrs  = _TargetAttrs[target]

                -- Check inheritance
                for i = 1, select("#", ...) do
                    local super = select(i, ...)
                    if super and _AttrTargetInrt[super] then
                        for _, sattr in pairs, _AttrTargetInrt[super] do
                            local aTar = getAttributeInfo(sattr, "AttributeTarget", ATTRTAR_ALL, "number")

                            if aTar == ATTRTAR_ALL or validateFlags(targetType, aTar) then
                                Trace("Inherit attribtue %s", tostring(sattr))
                                tarAttrs = tarAttrs or _Cache()
                                addAttribute(tarAttrs, sattr, true)
                            end
                        end
                    end
                end

                Trace("[attribute][InheritAttributes] <== [%s]%s", _AttrTargetTypes[targetType] or "Unknown", tostring(target))

                _TargetAttrs[target] = tarAttrs
            end;

            --- Register the attribute to be used by the next feature
            -- @static
            -- @method  Register
            -- @owner   attribute
            -- @format  attr[, noSameType]
            -- @param   attr            the attribute to be registered
            -- @param   noSameType      whether don't register the attribute if there is another attribute with the same type
            ["Register"]        = function(attr, noSameType)
                local attr      = attribute.ValidateValue(attr)
                if not attr then error("Usage : attribute.Register(attr) - the attr is not valid", 2) end
                Debug("[attribute][Register] %s", tostring(attr))
                return addAttribute(_RegisteredAttrs, attr, noSameType)
            end;

            --- Register an attribute type with usage information
            -- @static
            -- @method  RegisterAttributeType
            -- @owner   attribute
            -- @param   attributeType   the attribute type
            -- @param   usages          the attribute usages
            ["RegisterAttributeType"] = function(attrType, usage)
                if not attrType then
                    error("Usage: attribute.RegisterAttributeType(attrType, usage) - The attrType can't be nil", 2)
                end
                if _AttrTargetData[attrType] and _AttrTargetData[attrType][attribute] and _AttrTargetData[attrType][attribute].Final then
                    return
                end

                local extAttrs  = tblclone(_AttrTargetData[attrType], _Cache())
                local attrusage = _Cache()

                Debug("[attribute][RegisterAttributeType] %s", tostring(attrType))

                -- Default usage data for attributes
                attrusage.InitDefinition    = getAttrUsageField(usage,  "InitDefinition",   nil,        "function")
                attrusage.ApplyAttribute    = getAttrUsageField(usage,  "ApplyAttribute",   nil,        "function")
                attrusage.AttachAttribute   = getAttrUsageField(usage,  "AttachAttribute",  nil,        "function")
                attrusage.AttributeTarget   = getAttrUsageField(usage,  "AttributeTarget",  ATTRTAR_ALL,"number")
                attrusage.Inheritable       = getAttrUsageField(usage,  "Inheritable",      false)
                attrusage.Overridable       = getAttrUsageField(usage,  "Overridable",      true)
                attrusage.Priority          = getAttrUsageField(usage,  "Priority",         0,          "number")
                attrusage.SubLevel          = getAttrUsageField(usage,  "SubLevel",         0,          "number")

                -- A special data for attribute usage, so the attribute usage won't be overridden
                attrusage.Final             = getAttrUsageField(usage,  "Final",            false)

                extAttrs[attribute]         = attrusage
                _AttrTargetData             = saveStorage(_AttrTargetData, attrType, extAttrs)
            end;

            --- Register attribute target type
            -- @static
            -- @method  RegisterTargetType
            -- @owner   attribtue
            -- @param   name:string     the target type's name
            -- @return  flag:number     the target type's flag value
            ["RegisterTargetType"]  = function(name)
                local i             = 2^0
                while _AttrTargetTypes[i] do i = i * 2 end
                _AttrTargetTypes[i] = name
                Debug("[attribute][RegisterTargetType] %q = %d", name, i)
                return i
            end;

            --- Save the current registered attributes to the target
            -- @static
            -- @method  SaveAttributes
            -- @owner   attribtue
            -- @format  (target, targetType, [owner], [name][, stack])
            -- @param   target          the target
            -- @param   targetType      the target type
            -- @param   stack           the stack level
            ["SaveAttributes"]  = function(target, targetType, stack)
                if #_RegisteredAttrs  == 0 then return end

                local regAttrs  = _RegisteredAttrs
                _RegisteredAttrs= _Cache()

                Debug("[attribute][SaveAttributes] ==> [%s]%s", _AttrTargetTypes[targetType] or "Unknown", tostring(target))

                for i = #regAttrs, 1, -1 do
                    local attr  = regAttrs[i]
                    local aTar  = getAttributeInfo(attr, "AttributeTarget", ATTRTAR_ALL, "number")

                    if aTar ~= ATTRTAR_ALL and not validateFlags(targetType, aTar) then
                        if _UseWarnInstreadErr then
                            Warn("The attribute %s can't be applied to the [%s]%s", tostring(attr), _AttrTargetTypes[targetType] or "Unknown", tostring(target))
                            tremove(regAttrs, i)
                        else
                            _Cache(regAttrs)
                            error(strformat("The attribute %s can't be applied to the [%s]%s", tostring(attr), _AttrTargetTypes[targetType] or "Unknown", tostring(target)), stack)
                        end
                    end
                end

                Debug("[attribute][SaveAttributes] <== [%s]%s", _AttrTargetTypes[targetType] or "Unknown", tostring(target))

                _TargetAttrs[target] = regAttrs
            end;

            --- Toggle the target, save the old target's attributes to the new one
            -- @static
            -- @method  ToggleTarget
            -- @owner   attribtue
            -- @format  (old, new)
            -- @param   old             the old target
            -- @param   new             the new target
            ["ToggleTarget"]    = function(old, new)
                local tarAttrs  = _TargetAttrs[old]
                if tarAttrs and new and new ~= old then
                    _TargetAttrs[old] = nil
                    _TargetAttrs[new] = tarAttrs
                end
            end;

            --- Un-register an attribute
            -- @static
            -- @method  Unregister
            -- @owner   attribtue
            -- @param   attr            the attribtue to be un-registered
            ["Unregister"]      = function(attr)
                for i, v in ipairs, _RegisteredAttrs, 0 do
                    if v == attr then
                        Debug("[attribute][Unregister] %s", tostring(attr))
                        return tremove(_RegisteredAttrs, i)
                    end
                end
            end;

            --- Validate whether the attribute is valid or the attribute' type
            -- is the given one
            -- @static
            -- @method  ValidateValue
            -- @owner   attribtue
            -- @format  (attr[, attrType])
            -- @param   attr            the attribute to be validated
            -- @param   attrType        the attribute type
            -- @return  validated       true if the attribute is valid
            ["ValidateValue"]   = function(attr, attrType)
                if attrType then
                    return attribute.Validate(attrType) and attrType == getmetatable(attr) and attr or nil
                else
                    -- May use the default usage settings
                    local atype     = type(attr)
                    return (atype == "table" or atype == "userdata") and attr or nil
                end
            end;

            --- Validate whether the target is an attribute type
            -- @static
            -- @method  Validate
            -- @owner   attribtue
            -- @param   attrType        the attribtue type to be validated
            -- @return  validated       true if the attribute type is valid
            ["Validate"]        = function(attrtype)
                local info      = _AttrTargetData[attrtype]
                return info and info[attribute] and attrtype or nil
            end;
        },
        __newindex              = readOnly,
    }
end

-------------------------------------------------------------------------------
-- The environment is designed to be private and standalone for codes(Module)
-- or type building(class and etc). It provide features like keyword accessing,
-- namespace management, get/set management and etc.
--
--      -- Module is an environment type for codes works like _G
--      Module "Test" "v1.0.0"
--
--      -- Declare the namespace for the module
--      namespace "NS.Test"
--
--      -- Import other namespaces to the module
--      import "System.Threading"
--
--      -- By using the get/set management we can use attributes for features
--      -- like functions.
--      __Thread__()
--      function DoThreadTask()
--      end
--
--      -- The function with _ENV will be called within a private environment
--      -- where the class A's definition will be processed. The class A also
--      -- will be saved to the namespace NS.Test since its defined in the Test
--      -- Module.
--      class "A" (function(_ENV)
--          -- So the Score's path should be NS.Test.A.Score since it's defined
--          -- in the class A's definition environment whose namespace is the
--          -- class A.
--          enum "Score" { "A", "B", "C", "D" }
--      end)
--
-- @prototype   environment
-- @usage       -- The environment also can be used to call a function within a
--              -- private environment
--              environment(function(_ENV)
--                  import "System.Threading"
--
--                  __Thread__()
--                  function DoTask()
--                  end
--              end)
-------------------------------------------------------------------------------
do
    -----------------------------------------------------------------------
    --                         attribute targets                         --
    -----------------------------------------------------------------------
    ATTRTAR_FUNCTION            = attribute.RegisterTargetType("Function")

    -----------------------------------------------------------------------
    --                         private constants                         --
    -----------------------------------------------------------------------
    -- Environment Special Field
    local ENV_NS_OWNER          = "__PLOOP_ENV_OWNNS"
    local ENV_NS_IMPORTS        = "__PLOOP_ENV_IMPNS"
    local ENV_BASE_ENV          = "__PLOOP_ENV_BSENV"
    local ENV_GLOBAL_CACHE      = "__PLOOP_ENV_GLBCA"

    -----------------------------------------------------------------------
    --                          private storage                          --
    -----------------------------------------------------------------------
    -- Registered Keywords
    local _ContextKeywords      = {}    -- Keywords for environment type
    local _GlobalKeywords       = {}    -- Global keywords

    -- Keyword visitor
    local _KeyVisitor                   -- The environment that access the next keyword
    local _AccessKey                    -- The next keyword

    -----------------------------------------------------------------------
    --                             prototype                             --
    -----------------------------------------------------------------------
    environment                 = prototype {
        __tostring              = "environment",
        __index                 = {
            --- Get the namespace from the environment
            -- @static
            -- @method  GetNameSpace
            -- @owner   environment
            -- @param   env:table       the environment
            -- @return  ns              the namespace of the environment
            ["GetNameSpace"]    = function(env)
                env = env or getfenv(2)
                return namespace.Validate(type(env) == "table" and rawget(env, ENV_NS_OWNER))
            end;

            --- Get the parent environment from the environment
            -- @static
            -- @method  GetParent
            -- @owner   environment
            -- @param   env:table       the environment
            -- @return  parentEnv       the parent of the environment
            ["GetParent"]       = function(env)
                return type(env) == "table" and rawget(env, ENV_BASE_ENV) or nil
            end;

            --- Get the value from the environment based on its namespace and
            -- parent settings(normally be used in __newindex for environment),
            -- the keywords also must be fetched through it.
            -- @static
            -- @method  GetValue
            -- @owner   environment
            -- @format  (env, name, [noautocache][, stack])
            -- @param   env:table       the environment
            -- @param   name            the key of the value
            -- @param   noautocache     true if don't save the value to the environment, the keyword won't be saved
            -- @param   stack           the stack level
            -- @return  value           the value of the name in the environment
            ["GetValue"]        = (function()
                local head              = _Cache()
                local body              = _Cache()
                local upval             = _Cache()

                tinsert(body, "")
                tinsert(body, [[
                    return function(env, name, noautocache, stack)
                        local value
                ]])

                if PLOOP_PLATFORM_SETTINGS.MULTI_OS_THREAD and not PLOOP_PLATFORM_SETTINGS.MULTI_OS_THREAD_LUA_LOCK_APPLIED then
                    -- Don't cache global variables in the environment to avoid conflict
                    -- The cache should be full-hit during runtime after several operations
                    tinsert(body, [[
                        value = env["]] .. ENV_GLOBAL_CACHE .. [["][name]
                        if value ~= nil then return value end
                    ]])
                end

                tinsert(body, [[if type(name) == "string" then]])

                -- Check the keywords
                tinsert(head, "_GlobalKeywords")
                tinsert(upval, _GlobalKeywords)

                tinsert(head, "_ContextKeywords")
                tinsert(upval, _ContextKeywords)

                tinsert(head, "regKeyVisitor")
                tinsert(upval, function(env, keyword) _KeyVisitor, _AccessKey = env, keyword return keyword end)
                tinsert(body, [[
                    value = _GlobalKeywords[name]
                    if not value then
                        local keys = _ContextKeywords[getmetatable(env)]
                        value = keys and keys[name]
                    end
                    if value then
                        return regKeyVisitor(env, value)
                    end
                ]])

                -- Check current namespace
                tinsert(body, [[
                    local ns = namespace.Validate(rawget(env, "]] .. ENV_NS_OWNER .. [["))
                    if ns then
                        value = name == namespace.GetNameSpaceName(ns, true) and ns or ns[name]
                    end
                ]])

                -- Check imported namespaces
                tinsert(body, [[
                    if value == nil then
                        local imp = rawget(env, "]] .. ENV_NS_IMPORTS .. [[")
                        if type(imp) == "table" then
                            for _, sns in ipairs, imp, 0 do
                                sns = namespace.Validate(sns)
                                if sns then
                                    value = name == namespace.GetNameSpaceName(sns, true) and sns or sns[name]
                                    if value ~= nil then break end
                                end
                            end
                        end
                    end
                ]])

                -- Check root namespaces
                tinsert(body, [[
                    if value == nil then
                        value = namespace.GetNameSpace(name)
                    end
                ]])

                -- Check base environment
                tinsert(body, [[
                    if value == nil then
                        local parent = rawget(env, "]] .. ENV_BASE_ENV .. [[") or _G
                        if type(parent) == "table" then
                ]])
                if not PLOOP_PLATFORM_SETTINGS.ENV_ALLOW_GLOBAL_VAR_BE_NIL then
                    tinsert(head, "saferawget")
                    tinsert(body, function(self, key) return self[key] end)
                    tinsert(body, [[
                            local ok, ret = pcall(saferawget, parent, name)
                            if not ok or ret == nil then error(("The global variable %q can't be nil."):format(name), (stack or 1) + 1) end
                            value = ret
                    ]])
                else
                    tinsert(body, [[
                            value = parent[name]
                    ]])
                end
                tinsert(body, [[
                        end
                    end
                ]])

                -- Auto-Cache
                tinsert(body, [[
                    if value ~= nil and not noautocache then
                ]])

                if PLOOP_PLATFORM_SETTINGS.MULTI_OS_THREAD and not PLOOP_PLATFORM_SETTINGS.MULTI_OS_THREAD_LUA_LOCK_APPLIED then
                    tinsert(body, [[env["]] .. ENV_GLOBAL_CACHE .. [["] = saveStorage(env["]] .. ENV_GLOBAL_CACHE .. [["], name, value)]])
                    if PLOOP_PLATFORM_SETTINGS.MULTI_OS_THREAD_ENV_AUTO_CACHE_WARN then
                        tinsert(body, [[Warn("The %q is auto saved to %s", (stack or 1) + 1, name, tostring(env))]])
                    end
                else
                    tinsert(body, [[rawset(env, name, value)]])
                end

                tinsert(body, [[
                    end
                ]])

                tinsert(body, [[
                        end
                        return value
                    end
                ]])

                if #head > 0 then
                    body[1] = "local " .. tblconcat(head, ",") .. "= ..."
                end

                local func = loadSnippet(tblconcat(body, "\n"), "environment.GetValue")(unpack(upval))

                _Cache(head)
                _Cache(body)
                _Cache(upval)

                return func
            end)();

            --- Get the environment that visit the given keyword. The visitor
            -- use @environment.GetValue to access the keywords, so the system
            -- know where the keyword is called, this method is normally called
            -- by the keywords.
            -- @static
            -- @method  GetKeywordVisitor
            -- @owner   environment
            -- @param   keyword         the keyword
            -- @return  visitor         the keyword visitor(environment)
            ["GetKeywordVisitor"] = function(keyword)
                local visitor
                if _AccessKey  == keyword then visitor = _KeyVisitor end
                _KeyVisitor     = nil
                _AccessKey      = nil
                return visitor
            end;

            --- Import namespace to environment
            -- @static
            -- @method  ImportNameSpace
            -- @owner   environment
            -- @format  (env, ns[, stack])
            -- @param   env             the environment
            -- @param   ns              the namespace, it can be the namespace itself or its name path
            -- @param   stack           the stack level
            ["ImportNameSpace"] = function(env, ns, stack)
                ns = namespace.Validate(ns)
                if type(env) ~= "table" then error("Usage: environment.ImportNameSpace(env, namespace) - the env must be a table", (stack or 1) + 1) end
                if not ns then error("Usage: environment.ImportNameSpace(env, namespace) - The namespace is not provided", (stack or 1) + 1) end

                local imports   = rawget(env, ENV_NS_IMPORTS)
                if not imports then imports = newStorage(WEAK_VALUE) rawset(env, ENV_NS_IMPORTS, imports) end
                for _, v in ipairs, imports, 0 do if v == ns then return end end
                tinsert(imports, ns)
            end;

            --- Initialize the environment
            -- @static
            -- @method  Initialize
            -- @owner   environment
            -- @param   env             the environment
            ["Initialize"]      = PLOOP_PLATFORM_SETTINGS.MULTI_OS_THREAD and not PLOOP_PLATFORM_SETTINGS.MULTI_OS_THREAD_LUA_LOCK_APPLIED and function(env)
                if type(env) == "table" then rawset(env, ENV_GLOBAL_CACHE, {}) end
            end or fakefunc;

            --- Register a context keyword, like property must be used in the
            -- definition of a class or interface.
            -- @static
            -- @method  RegisterContextKeyword
            -- @owner   environment
            -- @format  (ctxType, [key, ]keyword)
            -- @param   ctxType         the context environment's type
            -- @param   key:string      the keyword's name, it'd be applied if the keyword is a function
            -- @param   keyword         the keyword entity
            -- @format  (ctxType, keywords)
            -- @param   keywords:table  a collection of the keywords like : { import = import , class, struct }
            ["RegisterContextKeyword"]= function(ctxType, key, keyword)
                if not ctxType or (type(ctxType) ~= "table" and type(ctxType) ~= "userdata") then
                    error("Usage: environment.RegisterContextKeyword(ctxType, key[, keyword]) - the ctxType isn't valid", 2)
                end
                _ContextKeywords[ctxType] = _ContextKeywords[ctxType] or {}
                local keywords            = _ContextKeywords[ctxType]

                if type(key) == "table" and getmetatable(key) == nil then
                    for k, v in pairs, key do
                        if type(k) ~= "string" then k = tostring(v) end
                        if not keywords[k] and v then keywords[k] = v end
                    end
                else
                    if type(key) ~= "string" then key, keyword= tostring(key), key end
                    if key and not keywords[key] and keyword then keywords[key] = keyword end
                end
            end;

            --- Register a global keyword
            -- @static
            -- @method  RegisterGlobalKeyword
            -- @owner   environment
            -- @format  ([key, ]keyword)
            -- @param   key:string      the keyword's name, it'd be applied if the keyword is a function
            -- @param   keyword         the keyword entity
            -- @format  (keywords)
            -- @param   keywords:table  a collection of the keywords like : { import = import , class, struct }
            ["RegisterGlobalKeyword"] = function(key, keyword)
                local keywords      = _GlobalKeywords

                if type(key) == "table" and getmetatable(key) == nil then
                    for k, v in pairs, key do
                        if type(k) ~= "string" then k = tostring(v) end
                        if not keywords[k] and v then keywords[k] = v end
                    end
                else
                    if type(key) ~= "string" then key, keyword = tostring(key), key end
                    if key and not keywords[key] and keyword then keywords[key] = keyword end
                end
            end;

            --- Save the value to the environment, useful to save attribtues for functions
            -- @static
            -- @method  SaveValue
            -- @owner   environment
            -- @format  (env, name, value[, stack])
            -- @param   env             the environment
            -- @param   name            the key
            -- @param   value           the value
            -- @param   stack           the stack level
            ["SaveValue"]       = function(env, key, value, stack)
                if type(key)   == "string" and type(value) == "function" then
                    attribute.SaveAttributes(value, ATTRTAR_FUNCTION, (stack or 1) + 1)

                    local final = attribute.InitDefinition(value, ATTRTAR_FUNCTION, value, env, key)

                    if type(final) == "function" and final ~= value then
                        attribute.ToggleTarget(value, final)
                        value   = final
                    end
                    attribute.ApplyAttributes (value, ATTRTAR_FUNCTION, env, key)
                    attribute.AttachAttributes(value, ATTRTAR_FUNCTION, env, key)
                end
                return rawset(env, key, value)
            end;

            --- Set the namespace to the environment
            -- @static
            -- @method  SetNameSpace
            -- @owner   environment
            -- @format  (env, ns[, stack])
            -- @param   env             the environment
            -- @param   ns              the namespace, it can be the namespace itself or its name path
            -- @param   stack           the stack level
            ["SetNameSpace"]    = function(env, ns, stack)
                if type(env) ~= "table" then error("Usage: environment.SetNameSpace(env, namespace) - the env must be a table", (stack or 1) + 1) end
                rawset(env, ENV_NS_OWNER, namespace.Validate(ns))
            end;

            --- Set the parent environment to the environment
            -- @static
            -- @method  SetParent
            -- @owner   environment
            -- @format  (env, base[, stack])
            -- @param   env             the environment
            -- @param   base            the base environment
            -- @param   stack           the stack level
            ["SetParent"]       = function(env, base, stack)
                if type(env) ~= "table" then error("Usage: environment.SetParent(env, [parentenv]) - the env must be a table", (stack or 1) + 1) end
                if base and type(base) ~= "table" then error("Usage: environment.SetParent(env, [parentenv]) - the parentenv must be a table", (stack or 1) + 1) end
                rawset(env, ENV_BASE_ENV, base or nil)
            end;
        },
        __newindex              = readOnly,
        __call                  = function(self, definition)
            local env           = prototype.NewObject(tenvironment)
            environment.Initialize(env)
            if definition then
                return env(definition)
            else
                return env
            end
        end,
    }

    tenvironment                = prototype {
        __index                 = environment.GetValue,
        __newindex              = environment.SaveValue,
        __call                  = function(self, definition)
            if type(definition) ~= "function" then error("Usage: environment(definition) - the definition must be a function", 2) end
            setfenv(definition, self)
            return definition(self)
        end,
    }

    -----------------------------------------------------------------------
    --                             keywords                              --
    -----------------------------------------------------------------------
    -----------------------------------------------------------------------
    -- import namespace to current environment
    --
    -- @keyword     import
    -- @usage       import "System.Threading"
    -----------------------------------------------------------------------
    import                      = function (...)
        local visitor, env, name, _, flag, stack  = GetFeatureParams(import, ...)

        name = namespace.Validate(name)
        if not env  then error("Usage: import(namespace) - The system can't figure out the environment", stack + 1) end
        if not name then error("Usage: import(namespace) - The namespace is not provided", stack + 1) end

        if visitor then
            return environment.ImportNameSpace(visitor, name)
        else
            return namespace.ExportNameSpace(env, name, flag)
        end
    end
end

-------------------------------------------------------------------------------
-- The namespaces are used to organize feature types. Same name features can be
-- saved in different namespaces so there won't be any conflict. Environment
-- can have a root namespace so all features defined in it will be saved to the
-- root namespace, also it can import several other namespaces, features that
-- defined in them can be used in the environment directly.
--
-- @prototype   namespace
-- @usage       -- Normally should be used within private code environment
--              environment(function(_ENV)
--                  namespace "NS.Test"
--
--                  class "A" {}  -- NS.Test.A
--              end)
--
--              -- Also you can use a pure namespace like using environment
--              NS.Test (function(_ENV)
--                  class "A" {}  -- NS.Test.A
--              end)
-------------------------------------------------------------------------------
do
    -----------------------------------------------------------------------
    --                         attribute targets                         --
    -----------------------------------------------------------------------
    ATTRTAR_NAMESPACE           = attribute.RegisterTargetType("Namespace")

    -----------------------------------------------------------------------
    --                          private storage                          --
    -----------------------------------------------------------------------
    local _NSTree               = newStorage(WEAK_KEY)
    local _NSName               = newStorage(WEAK_KEY)

    -- Shortcut
    local Validate
    local GetNameSpace

    -----------------------------------------------------------------------
    --                             prototype                             --
    -----------------------------------------------------------------------
    namespace                   = prototype {
        __tostring              = "namespace",
        __index                 = {
            --- Export a namespace and its children to an environment
            -- @static
            -- @method  ExportNameSpace
            -- @owner   namespace
            -- @format  (env, ns[, override][, stack])
            -- @param   env             the environment
            -- @param   ns              the namespace
            -- @param   override        whether override the existed value in the environment, Default false
            -- @param   stack           the stack level
            ["ExportNameSpace"] = function(env, ns, override, stack)
                if type(env)   ~= "table" then error("Usage: namespace.ExportNameSpace(env, namespace[, override]) - the env must be a table", (stack or 1) + 1) end
                ns  = Validate(ns)
                if not ns then error("Usage: namespace.ExportNameSpace(env, namespace[, override]) - The namespace is not provided", (stack or 1) + 1) end

                local nsname    = _NSName[ns]
                if nsname then
                    nsname      = strmatch(nsname, "[^%s%p]+$")
                    if override or rawget(env, nsname) == nil then rawset(env, nsname, ns) end
                end

                if _NSTree[ns] then
                    for name, sns in pairs, _NSTree[ns] do
                        if override or rawget(env, name) == nil then rawset(env, name, sns) end
                    end
                end
            end;

            --- Get the namespace by path
            -- @static
            -- @method  GetNameSpace
            -- @owner   namespace
            -- @format  ([root, ]path)
            -- @param   root            the root namespace
            -- @param   path:string     the namespace path
            -- @return  ns              the namespace
            ["GetNameSpace"]    = function(root, path)
                if type(root)  == "string" then
                    root, path  = ROOT_NAMESPACE, root
                elseif root    == nil then
                    root        = ROOT_NAMESPACE
                else
                    root        = Validate(root)
                end

                if root and type(path) == "string" then
                    local iter      = strgmatch(path, "[^%s%p]+")
                    local subname   = iter()

                    while subname do
                        local nodes = _NSTree[root]
                        root        = nodes and nodes[subname]
                        if not root then return end

                        local nxt   = iter()
                        if not nxt  then return root end

                        subname     = nxt
                    end
                end
            end;

            --- Get the namespace's path
            -- @static
            -- @method  GetNameSpaceName
            -- @owner   namespace
            -- @format  (ns[, lastOnly])
            -- @param   ns              the namespace
            -- @parma   lastOnly        whether only the last name of the namespace's path
            -- @return  string          the path of the namespace or the name of it if lastOnly is true
            ["GetNameSpaceName"]= function(ns, onlyLast)
                local name = _NSName[Validate(ns)]
                return name and (onlyLast and strmatch(name, "[^%s%p]+$") or name) or "Anonymous"
            end;

            --- Save feature to the namespace
            -- @static
            -- @method  SaveNameSpace
            -- @owner   namespace
            -- @format  ([root, ]path, feature[, stack])
            -- @param   root            the root namespace
            -- @param   path:string     the path of the feature
            -- @param   feature         the feature, must be table or userdata
            -- @param   stack           the stack level
            ["SaveNameSpace"]   = function(root, path, feature, stack)
                if type(root)  == "string" then
                    root, path, feature, stack = ROOT_NAMESPACE, root, path, feature
                elseif root    == nil then
                    root        = ROOT_NAMESPACE
                else
                    root        = Validate(root)
                end

                if stack ~= nil and type(stack) ~= "number" then
                    error("Usage: namespace.SaveNameSpace([root, ]path, feature[, stack]) - the stack must be number", 2)
                end
                if root == nil then
                    error("Usage: namespace.SaveNameSpace([root, ]path, feature[, stack]) - the root must be namespace", (stack or 1) + 1)
                end
                if type(path) ~= "string" or strtrim(path) == "" then
                    error("Usage: namespace.SaveNameSpace([root, ]path, feature[, stack]) - the path must be string", (stack or 1) + 1)
                else
                    path    = strtrim(path)
                end
                if type(feature) ~= "table" and type(feature) ~= "userdata" then
                    error("Usage: namespace.SaveNameSpace([root, ]path, feature[, stack]) - the feature should be userdata or table", (stack or 1) + 1)
                end

                if _NSName[feature] ~= nil then
                    local epath = _Cache()
                    if _NSName[root] then tinsert(epath, _NSName[root]) end
                    path:gsub("[^%s%p]+", function(name) tinsert(epath, name) end)
                    if tblconcat(epath, ".") == _NSName[feature] then
                        return
                    else
                        error("Usage: namespace.SaveNameSpace([root, ]path, feature[, stack]) - already registered as " .. (_NSName[feature] or "Anonymous"), (stack or 1) + 1)
                    end
                end

                local iter      = strgmatch(path, "[^%s%p]+")
                local subname   = iter()

                while subname do
                    local nodes = _NSTree[root]
                    if not nodes then
                        nodes   = {}
                        _NSTree = saveStorage(_NSTree, root, nodes)
                    end

                    local subns = nodes[subname]
                    local nxt   = iter()

                    if not nxt then
                        if subns then
                            if subns == feature then return end
                            error("Usage: namespace.SaveNameSpace([root, ]path, feature[, stack]) - the namespace path has already be used by others", (stack or 1) + 1)
                        else
                            _NSName         = saveStorage(_NSName, feature, _NSName[root] and (_NSName[root] .. "." .. subname) or subname)
                            _NSTree[root]   = saveStorage(nodes, subname, feature)
                        end
                    elseif not subns then
                        subns = prototype.NewProxy(tnamespace)

                        _NSName             = saveStorage(_NSName, subns, _NSName[root] and (_NSName[root] .. "." .. subname) or subname)
                        _NSTree[root]       = saveStorage(nodes, subname, subns)
                    end

                    root, subname = subns, nxt
                end
            end;

            --- Save anonymous namespace, anonymous namespace also can be used
            -- as new root of another namespace tree.
            -- @static
            -- @method  SaveAnonymousNameSpace
            -- @owner   namespace
            -- @param   feature         the feature, must be table or userdata
            -- @param   stack           the stack level
            ["SaveAnonymousNameSpace"] = function(feature, stack)
                if stack ~= nil and type(stack) ~= "number" then
                    error("Usage: namespace.SaveAnonymousNameSpace(feature[, stack]) - the stack must be number", 2)
                end
                if type(feature) ~= "table" and type(feature) ~= "userdata" then
                    error("Usage: namespace.SaveAnonymousNameSpace(feature[, stack]) - the feature should be userdata or table", (stack or 1) + 1)
                end
                if _NSName[feature] then
                    error("Usage: namespace.SaveAnonymousNameSpace(feature[, stack]) - the feature already registered as " .. _NSName[feature], (stack or 1) + 1)
                end
                _NSName         = saveStorage(_NSName, feature, false)
            end;

            --- Whether the target is a namespace
            -- @static
            -- @method  Validate
            -- @owner   namespace
            -- @param   target          the query feature
            -- @return  target          nil if not namespace
            ["Validate"]        = function(target)
                if type(target) == "string" then return GetNameSpace(target) end
                return _NSName[target] ~= nil and target or nil
            end;
        },
        __newindex              = readOnly,
        __call                  = function(self, ...)
            local visitor, env, target, _, flag, stack = GetFeatureParams(namespace, ...)

            if not env then error("Usage: namespace([env, ]path[, noset][, stack]) - the system can't figure out the environment", stack + 1) end

            if target ~= nil then
                if type(target) == "string" then
                    local ns    = GetNameSpace(target)
                    if not ns then
                        ns = prototype.NewProxy(tnamespace)
                        attribute.SaveAttributes(ns, ATTRTAR_NAMESPACE, stack + 1)
                        namespace.SaveNameSpace(target, ns, stack + 1)
                        attribute.AttachAttributes(ns, ATTRTAR_NAMESPACE)
                        target    = ns
                    end
                else
                    target = Validate(target)
                end

                if not target then error("Usage: namespace([env, ]path[, noset][, stack]) - the system can't figure out the namespace", stack + 1) end
            end

            if not flag then
                if visitor then environment.SetNameSpace(visitor, target) end
                if env and env ~= visitor then  environment.SetNameSpace(env, target) end
            end

            return target
        end,
    }

    -- default type for namespace
    tnamespace                  = prototype {
        __index                 = namespace.GetNameSpace,
        __newindex              = readOnly,
        __tostring              = namespace.GetNameSpaceName,
        __metatable             = namespace,
        __concat                = typeconcat,
        __call                  = function(self, definition)
            local env           = prototype.NewObject(tenvironment)
            environment.Initialize(env)
            environment.SetNameSpace(env, self)
            if definition then
                return env(definition)
            else
                return env
            end
        end,
    }

    -----------------------------------------------------------------------
    --                            Initialize                             --
    -----------------------------------------------------------------------
    -- Shortcut Assignment
    Validate                    = namespace.Validate
    GetNameSpace                = namespace.GetNameSpace

    -- Init the root namespace
    ROOT_NAMESPACE              = prototype.NewProxy(tnamespace)
    namespace.SaveAnonymousNameSpace(ROOT_NAMESPACE)
end

-------------------------------------------------------------------------------
-- An enumeration is a data type consisting of a set of named values called
-- elements, The enumerator names are usually identifiers that behave as
-- constants.
--
-- To define an enum within the PLoop, the syntax is
--
--      enum "Name" { -- key-value pairs }
--
-- In the table, for each key-value pair, if the key is string, the key would
-- be used as the element's name and the value is the element's value. If the
-- key is a number and the value is string, the value would be used as both the
-- element's name and value, othwise the key-value pair will be ignored.
--
-- Use enumeration[elementname] to fetch or validate the enum element's value,
-- also can use enumeration(value) to fetch the element name from value. Here
-- is an example :
--
--      enum "Direction" { North = 1, East = 2, South = 3, West = 4 }
--      print(Direction.South) -- 3
--      print(Direction[3])    -- 3
--      print(Direction.NoDir) -- nil
--
--      print(Direction(3))    -- South
--
-- @prototype   enum
-------------------------------------------------------------------------------
do
    -----------------------------------------------------------------------
    --                         attribute targets                         --
    -----------------------------------------------------------------------
    ATTRTAR_ENUM                = attribute.RegisterTargetType("Enum")

    -----------------------------------------------------------------------
    --                         private constants                         --
    -----------------------------------------------------------------------
    -- FEATURE MODIFIER
    local MOD_SEALED_ENUM       = 2^0   -- SEALED
    local MOD_FLAGS_ENUM        = 2^1   -- FLAGS
    local MOD_NOT_FLAGS         = 2^2   -- NOT FLAG
    local MOD_CASE_IGNORED      = 2^3   -- CASE IGNORED

    local MOD_ENUM_INIT         = PLOOP_PLATFORM_SETTINGS.ENUM_GLOBAL_IGNORE_CASE and MOD_CASE_IGNORED or 0

    -- FIELD INDEX
    local FLD_ENUM_MOD          = 0     -- FIELD MODIFIER
    local FLD_ENUM_ITEMS        = 1     -- FIELD ENUMERATIONS
    local FLD_ENUM_CACHE        = 2     -- FIELD CACHE : VALUE -> NAME
    local FLD_ENUM_ERRMSG       = 3     -- FIELD ERROR MESSAGE
    local FLD_ENUM_VALID        = 4     -- FIELD VALIDATOR
    local FLD_ENUM_MAXVAL       = 5     -- FIELD MAX VALUE(FOR FLAGS)
    local FLD_ENUM_DEFAULT      = 6     -- FIELD DEFAULT

    -- Flags
    local FLG_FLAGS_ENUM        = 2^0
    local FLG_CASE_IGNORED      = 2^1

    -----------------------------------------------------------------------
    --                          private storage                          --
    -----------------------------------------------------------------------
    local _EnumInfo             = newStorage(WEAK_KEY)

    -- BUILD CACHE
    local _EnumBuilderInfo      = newStorage(WEAK_KEY)
    local _EnumValidMap         = {}

    -----------------------------------------------------------------------
    --                          private helpers                          --
    -----------------------------------------------------------------------
    local getEnumTargetInfo     = function (target)
        local info  = _EnumBuilderInfo[target]
        if info then return info, true else return _EnumInfo[target], false end
    end

    local genEnumValidator      = function (info)
        local token = 0

        if validateFlags(MOD_CASE_IGNORED, info[FLD_ENUM_MOD]) then
            token   = turnOnFlags(FLG_CASE_IGNORED, token)
        end

        if validateFlags(MOD_FLAGS_ENUM, info[FLD_ENUM_MOD]) then
            token   = turnOnFlags(FLG_FLAGS_ENUM, token)
        end

        if not _EnumValidMap[token] then
            local body      = _Cache()

            tinsert(body, "")   -- Remain for closure values
            tinsert(body, [[
                return function(info, value)
                    local cache = info[]] .. FLD_ENUM_CACHE .. [[]
                    if cache[value] then return value end
            ]])

            if validateFlags(FLG_CASE_IGNORED, token) or validateFlags(FLG_FLAGS_ENUM, token) then
                tinsert(body, [[
                    local vtype = type(value)
                    if vtype == "string" then
                ]])

                if validateFlags(FLG_CASE_IGNORED, token) then
                    tinsert(body, [[value = strupper(value)]])
                end
            end

            tinsert(body, [[value = info[]] .. FLD_ENUM_ITEMS .. [[][value] ]])

            if validateFlags(FLG_FLAGS_ENUM, token) then
                tinsert(body, [[
                    elseif vtype == "number" then
                        if value == 0 then
                            if cache[0] then return 0 end
                        elseif floor(value) == value and value > 0 and value <= info[]] .. FLD_ENUM_MAXVAL .. [[] then
                            return value
                        end
                ]])
            end

            if validateFlags(FLG_CASE_IGNORED, token) or validateFlags(FLG_FLAGS_ENUM, token) then
                tinsert(body, [[
                    else
                        value = nil
                    end
                ]])
            end

            tinsert(body, [[
                    return value, value == nil and info[]] .. FLD_ENUM_ERRMSG .. [[] or nil
                end
            ]])

            _EnumValidMap[token] = loadSnippet(tblconcat(body, "\n"), "Enum_Validate_" .. token)()

            _Cache(body)
        end

        info[FLD_ENUM_VALID] = _EnumValidMap[token]
    end

    -----------------------------------------------------------------------
    --                             prototype                             --
    -----------------------------------------------------------------------
    enum                        = prototype {
        __tostring              = "enum",
        __index                 = {
            --- Add key-value pair to the enumeration
            -- @static
            -- @method  AddElement
            -- @owner   enum
            -- @format  (enumeration, key, value[, stack])
            -- @param   enumeration     the enumeration
            -- @param   key             the element name
            -- @param   value           the element value
            -- @param   stack           the stack level
            ["AddElement"]    = function(target, key, value, stack)
                local info, def = getEnumTargetInfo(target)
                stack = type(stack) == "number" and stack or 1

                if info then
                    if not def then error(strformat("Usage: enum.AddElement(enumeration, key, value[, stack]) - The %s's definition is finished", tostring(target)), stack + 1) end
                    if type(key) ~= "string" then error("Usage: enum.AddElement(enumeration, key, value[, stack]) - The key must be a string", stack + 1) end

                    for k, v in pairs, info[FLD_ENUM_ITEMS] do
                        if strupper(k) == strupper(key) then
                            if (validateFlags(MOD_CASE_IGNORED, info[FLD_ENUM_MOD]) and strupper(key) or key) == k and v == value then return end
                            error("Usage: enum.AddElement(enumeration, key, value[, stack]) - The key already existed", stack + 1)
                        elseif v == value then
                            error("Usage: enum.AddElement(enumeration, key, value[, stack]) - The value already existed", stack + 1)
                        end
                    end

                    info[FLD_ENUM_ITEMS][validateFlags(MOD_CASE_IGNORED, info[FLD_ENUM_MOD]) and strupper(key) or key] = value
                else
                    error("Usage: enum.AddElement(enumeration, key, value[, stack]) - The enumeration is not valid", stack + 1)
                end
            end;

            --- Begin the enumeration's definition
            -- @static
            -- @method  BeginDefinition
            -- @owner   enum
            -- @format  (enumeration[, stack])
            -- @param   enumeration     the enumeration
            -- @param   stack           the stack level
            ["BeginDefinition"] = function(target, stack)
                stack   = type(stack) == "number" and stack or 1
                target  = enum.Validate(target)
                if not target then error("Usage: enum.BeginDefinition(enumeration[, stack]) - the enumeration not existed", stack + 1) end

                local info      = _EnumInfo[target]

                -- if info and validateFlags(MOD_SEALED_ENUM, info[FLD_ENUM_MOD]) then error(strformat("Usage: enum.BeginDefinition(enumeration[, stack]) - The %s is sealed, can't be re-defined", tostring(target)), stack + 1) end
                if _EnumBuilderInfo[target] then error(strformat("Usage: enum.BeginDefinition(enumeration[, stack]) - The %s's definition has already begun", tostring(target)), stack + 1) end

                _EnumBuilderInfo = saveStorage(_EnumBuilderInfo, target, info and validateFlags(MOD_SEALED_ENUM, info[FLD_ENUM_MOD]) and tblclone(info, {}, true, true) or {
                    [FLD_ENUM_MOD    ]  = MOD_ENUM_INIT,
                    [FLD_ENUM_ITEMS  ]  = {},
                    [FLD_ENUM_CACHE  ]  = {},
                    [FLD_ENUM_ERRMSG ]  = "%s must be a value of [" .. tostring(target) .."]",
                    [FLD_ENUM_VALID  ]  = false,
                    [FLD_ENUM_MAXVAL ]  = false,
                    [FLD_ENUM_DEFAULT]  = nil,
                })

                attribute.SaveAttributes(target, ATTRTAR_ENUM, stack + 1)
            end;

            --- End the enumeration's definition
            -- @static
            -- @method  EndDefinition
            -- @owner   enum
            -- @format  (enumeration[, stack])
            -- @param   enumeration     the enumeration
            -- @param   stack           the stack level
            ["EndDefinition"]   = function(target, stack)
                local ninfo     = _EnumBuilderInfo[target]
                if not ninfo then return end

                stack = type(stack) == "number" and stack or 1

                attribute.ApplyAttributes(target, ATTRTAR_ENUM)

                _EnumBuilderInfo = saveStorage(_EnumBuilderInfo, target, nil)

                local enums = ninfo[FLD_ENUM_ITEMS]
                local cache = wipe(ninfo[FLD_ENUM_CACHE])

                for k, v in pairs, enums do cache[v] = k end

                -- Check Flags Enumeration
                if validateFlags(MOD_FLAGS_ENUM, ninfo[FLD_ENUM_MOD]) then
                    -- Mark the max value
                    local max = 1
                    for k, v in pairs, enums do
                        while v >= max do max = max * 2 end
                    end

                    ninfo[FLD_ENUM_MAXVAL]  = max - 1
                else
                    ninfo[FLD_ENUM_MAXVAL]  = false
                    ninfo[FLD_ENUM_MOD]     = turnOnFlags(MOD_NOT_FLAGS, ninfo[FLD_ENUM_MOD])
                end

                genEnumValidator(ninfo)

                -- Check Default
                if ninfo[FLD_ENUM_DEFAULT] ~= nil then
                    ninfo[FLD_ENUM_DEFAULT]  = ninfo[FLD_ENUM_VALID](ninfo, ninfo[FLD_ENUM_DEFAULT])
                    if ninfo[FLD_ENUM_DEFAULT] == nil then
                        error(ninfo[FLD_ENUM_ERRMSG]:format("The default"), stack + 1)
                    end
                end

                -- Save as new enumeration's info
                _EnumInfo       = saveStorage(_EnumInfo, target, ninfo)

                attribute.AttachAttributes(target, ATTRTAR_ENUM)

                return target
            end;

            --- Get the default value from the enumeration
            -- @static
            -- @method  GetDefault
            -- @owner   enum
            -- @param   enumeration     the enumeration
            -- @return  default         the default value
            ["GetDefault"]      = function(target)
                local info      = getEnumTargetInfo(target)
                return info and info[FLD_ENUM_DEFAULT]
            end;

            --- Get the elements from the enumeration
            -- @static
            -- @method  GetEnumValues
            -- @owner   enum
            -- @format  (enumeration[, cache])
            -- @param   enumeration     the enumeration
            -- @param   cache           the table used to cache those elements
            -- @rformat (iter, enum)    If cache is nil, the iterator will be returned
            -- @rformat (cache)         the cache table if used
            ["GetEnumValues"]   = function(target, cache)
                local info      = _EnumInfo[target]
                if info then
                    if cache then
                        return tblclone(info[FLD_ENUM_ITEMS], type(cache) == "table" and wipe(cache) or {})
                    else
                        info    = info[FLD_ENUM_ITEMS]
                        return function(self, key) return next(info, key) end, target
                    end
                end
            end;

            --- Whether the enumeration is case ignored
            -- @static
            -- @method  IsCaseIgnored
            -- @owner   enum
            -- @param   enumeration     the enumeration
            -- @return  boolean         true if the enumeration is case ignored
            ["IsCaseIgnored"]   = function(target)
                local info      = getEnumTargetInfo(target)
                return info and validateFlags(MOD_CASE_IGNORED, info[FLD_ENUM_MOD]) or false
            end;

            --- Whether the enumeration element values only are flags
            -- @static
            -- @method  IsFlagsEnum
            -- @owner   enum
            -- @param   enumeration     the enumeration
            -- @return  boolean         true if the enumeration element values only are flags
            ["IsFlagsEnum"]     = function(target)
                local info      = getEnumTargetInfo(target)
                return info and validateFlags(MOD_FLAGS_ENUM, info[FLD_ENUM_MOD]) or false
            end;

            --- Whether the enum's value is immutable through the validation, always false.
            -- @static
            -- @method  IsImmutable
            -- @owner   enum
            -- @param   enumeration     the enumeration
            -- @return  false
            ["IsImmutable"]     = function(target)
                return false
            end;

            --- Whether the enumeration is sealed, so can't be re-defined
            -- @static
            -- @method  IsSealed
            -- @owner   enum
            -- @param   enumeration     the enumeration
            -- @return  boolean         true if the enumeration is sealed
            ["IsSealed"]        = function(target)
                local info      = getEnumTargetInfo(target)
                return info and validateFlags(MOD_SEALED_ENUM, info[FLD_ENUM_MOD]) or false
            end;

            --- Whether the enumeration is sub-type of others, always false, needed by struct system
            -- @static
            -- @method  IsSubType
            -- @owner   enum
            -- @param   enumeration     the enumeration
            -- @param   super           the super type
            -- @return  false
            ["IsSubType"]       = function() return false end;

            --- Parse the element value to element name
            -- @static
            -- @method  Parse
            -- @owner   enum
            -- @format  (enumeration, value[, cache])
            -- @param   enumeration     the enumeration
            -- @param   value           the value
            -- @param   cache           the table used to cache the result, only used when the enumeration is flag enum
            -- @rformat (name)          only if the enumeration is not flags enum
            -- @rformat (iter, enum)    If cache is nil and the enumeration is flags enum, the iterator will be returned
            -- @rformat (cache)         if the cache existed and the enumeration is flags enum
            ["Parse"]           = function(target, value, cache)
                local info      = _EnumInfo[target]
                if info then
                    local ecache= info[FLD_ENUM_CACHE]

                    if info[FLD_ENUM_MAXVAL] then
                        if cache then
                            local ret = type(cache) == "table" and wipe(cache) or {}

                            if type(value) == "number" and floor(value) == value and value >= 0 and value <= info[FLD_ENUM_MAXVAL] then
                                if value > 0 then
                                    local ckv = 1

                                    while ckv <= value and ecache[ckv] do
                                        if validateFlags(ckv, value) then ret[ecache[ckv]] = ckv end
                                        ckv = ckv * 2
                                    end
                                elseif value == 0 and ecache[0] then
                                    ret[ecache[0]] = 0
                                end
                            end

                            return ret
                        elseif type(value) == "number" and floor(value) == value and value >= 0 and value <= info[FLD_ENUM_MAXVAL] then
                            if value == 0 then
                                return function(self, key) if not key then return ecache[0], 0 end end, target
                            else
                                local ckv = 1
                                return function(self, key)
                                    while ckv <= value and ecache[ckv] do
                                        local v = ckv
                                        ckv = ckv * 2
                                        if validateFlags(v, value) then return ecache[v], v end
                                    end
                                end
                            end
                        else
                            return fakefunc, target
                        end
                    else
                        return ecache[value]
                    end
                end
            end;

            --- Set the enumeration's default value
            -- @static
            -- @method  SetDefault
            -- @owner   enum
            -- @format  (enumeration, default[, stack])
            -- @param   enumeration     the enumeration
            -- @param   default         the default value or name
            -- @param   stack           the stack level
            ["SetDefault"]      = function(target, default, stack)
                local info, def = getEnumTargetInfo(target)
                stack = type(stack) == "number" and stack or 1

                if info then
                    if not def then error(strformat("Usage: enum.SetDefault(enumeration, default[, stack]) - The %s's definition is finished", tostring(target)), stack + 1) end
                    info[FLD_ENUM_DEFAULT] = default
                else
                    error("Usage: enum.SetDefault(enumeration, default[, stack]) - The enumeration is not valid", stack + 1)
                end
            end;

            --- Set the enumeration as case ignored
            -- @static
            -- @method  SetCaseIgnored
            -- @owner   enum
            -- @format  (enumeration[, stack])
            -- @param   enumeration     the enumeration
            -- @param   stack           the stack level
            ["SetCaseIgnored"]  = function(target, stack)
                local info, def = getEnumTargetInfo(target)
                stack = type(stack) == "number" and stack or 1

                if info then
                    if not validateFlags(MOD_CASE_IGNORED, info[FLD_ENUM_MOD]) then
                        if not def then error(strformat("Usage: enum.SetCaseIgnored(enumeration[, stack]) - The %s's definition is finished", tostring(target)), stack + 1) end
                        info[FLD_ENUM_MOD] = turnOnFlags(MOD_CASE_IGNORED, info[FLD_ENUM_MOD])

                        local enums     = info[FLD_ENUM_ITEMS]
                        local nenums    = _Cache()
                        for k, v in pairs, enums do nenums[strupper(k)] = v end
                        info[FLD_ENUM_ITEMS]  = nenums
                        _Cache(enums)
                    end
                else
                    error("Usage: enum.SetCaseIgnored(enumeration[, stack]) - The enumeration is not valid", stack + 1)
                end
            end;

            --- Set the enumeration as flags enum
            -- @static
            -- @method  SetFlagsEnum
            -- @owner   enum
            -- @format  (enumeration[, stack])
            -- @param   enumeration     the enumeration
            -- @param   stack           the stack level
            ["SetFlagsEnum"]    = function(target, stack)
                local info, def = getEnumTargetInfo(target)
                stack = type(stack) == "number" and stack or 1

                if info then
                    if not validateFlags(MOD_FLAGS_ENUM, info[FLD_ENUM_MOD]) then
                        if not def then error(strformat("Usage: enum.SetFlagsEnum(enumeration[, stack]) - The %s's definition is finished", tostring(target)), stack + 1) end
                        if validateFlags(MOD_NOT_FLAGS, info[FLD_ENUM_MOD]) then error(strformat("Usage: enum.SetFlagsEnum(enumeration[, stack]) - The %s is defined as non-flags enumeration", tostring(target)), stack + 1) end
                        info[FLD_ENUM_MOD] = turnOnFlags(MOD_FLAGS_ENUM, info[FLD_ENUM_MOD])
                    end
                else
                    error("Usage: enum.SetFlagsEnum(enumeration[, stack]) - The enumeration is not valid", stack + 1)
                end
            end;

            --- Seal the enumeration, so it can't be re-defined
            -- @static
            -- @method  SetSealed
            -- @owner   enum
            -- @format  (enumeration[, stack])
            -- @param   enumeration     the enumeration
            -- @param   stack           the stack level
            ["SetSealed"]       = function(target, stack)
                local info      = getEnumTargetInfo(target)
                stack = type(stack) == "number" and stack or 1

                if info then
                    if not validateFlags(MOD_SEALED_ENUM, info[FLD_ENUM_MOD]) then
                        info[FLD_ENUM_MOD] = turnOnFlags(MOD_SEALED_ENUM, info[FLD_ENUM_MOD])
                    end
                else
                    error("Usage: enum.SetSealed(enumeration[, stack]) - The enumeration is not valid", stack + 1)
                end
            end;

            --- Whether the check value contains the target flag value
            -- @static
            -- @method  ValidateFlags
            -- @owner   enum
            -- @param   target          the target value only should be 2^n
            -- @param   check           the check value
            -- @param   boolean         true if the check value contains the target value
            -- @usage   print(enum.ValidateFlags(4, 7)) -- true : 7 = 1 + 2 + 4
            ["ValidateFlags"]   = validateFlags;

            --- Whether the value is the enumeration's element's name or value
            -- @static
            -- @method  ValidateValue
            -- @owner   enum
            -- @param   enumeration     the enumeration
            -- @param   value           the value
            -- @return  value           the element value, nil if not pass the validation
            -- @return  errormessage    the error message if not pass
            ["ValidateValue"]   = function(target, value)
                local info      = _EnumInfo[target]
                if info then
                    return info[FLD_ENUM_VALID](info, value)
                else
                    error("Usage: enum.ValidateValue(enumeration, value) - The enumeration is not valid", 2)
                end
            end;

            --- Whether the value is an enumeration
            -- @static
            -- @method  Validate
            -- @owner   enum
            -- @param   enumeration     the enumeration
            -- @return  enumeration     nil if not pass the validation
            ["Validate"]        = function(target)
                return getmetatable(target) == enum and target or nil
            end;
        },
        __newindex              = readOnly,
        __call                  = function(self, ...)
            local visitor, env, target, definition, flag, stack  = GetTypeParams(enum, tenum, ...)
            if not target then
                error("Usage: enum([env, ][name, ][definition][, stack]) - the enumeration type can't be created", stack + 1)
            elseif definition ~= nil and type(definition) ~= "table" then
                error("Usage: enum([env, ][name, ][definition][, stack]) - the definition should be a table", stack + 1)
            end

            enum.BeginDefinition(target, stack + 1)

            local builder = prototype.NewObject(enumbuilder)
            environment.SetNameSpace(builder, target)

            if definition then
                builder(definition, stack + 1)
                return target
            else
                return builder
            end
        end,
    }

    tenum                       = prototype (tnamespace, {
        __index                 = enum.ValidateValue,
        __call                  = enum.Parse,
        __metatable             = enum,
    })

    enumbuilder                 = prototype {
        __index                 = writeOnly,
        __newindex              = readOnly,
        __call                  = function(self, definition, stack)
            stack   = (type(stack) == "number" and stack or 1) + 1
            if type(definition) ~= "table" then error("Usage: enum([env, ][name, ][stack]) {...} - The definition table is missing", stack) end

            local owner = environment.GetNameSpace(self)
            if not owner then error("The enumeration can't be found", stack) end
            if not _EnumBuilderInfo[owner] then error(strformat("The %s's definition is finished", tostring(owner)), stack) end

            local final = attribute.InitDefinition(owner, ATTRTAR_ENUM, definition)

            if type(final) == "table" then
                definition = final
            end

            for k, v in pairs, definition do
                if type(k) == "string" then
                    enum.AddElement(owner, k, v, stack)
                elseif type(v) == "string" then
                    enum.AddElement(owner, v, v, stack)
                end
            end

            enum.EndDefinition(owner, stack)
            return owner
        end,
    }
end

-------------------------------------------------------------------------------
-- The structures are types for basic and complex organized datas and also the
-- data contracts for value validation. There are three struct types:
--
--  i. Custom    The basic data types like number, string and more advanced
--          types like nature number. Take the Number as an example:
--
--                  struct "Number" (function(_ENV)
--                      function Number(value)
--                          return type(value) ~= "number" and "%s must be number"
--                      end
--                  end)
--
--                  v = Number(true)  -- Error : the value must be number
--
--              Unlike the enumeration, the structure's definition is a little
--          complex, the definition body is a function with _ENV as its first
--          parameter, the pattern is designed to make sure the PLoop works
--          with Lua 5.1 and all above versions. The code in the body function
--          will be processed in a private context used to define the struct.
--
--              The function with the struct's name is the validator, also you
--          can use `__valid` instead of the struct's name(There are anonymous
--          structs). The validator would be called with the target value, if
--          the return value is non-false, that means the target value don't
--          pass the validation, normally the return value should be an error
--          message, the `%s` in the message'll be replaced by words based on
--          where it's used, if the return value is true, the system would
--          generte an error message for it.
--
--              If the struct has only the validator, it's an immutable struct
--          that won't modify the validated value. We also need mutable struct
--          like Boolean :
--
--                  struct "Boolean" (function(_ENV)
--                      function __init(value)
--                          return value and true or fale
--                      end
--                  end)
--
--                  print(Boolean(1))  -- true
--
--              The function named `__init` is the initializer, it's used to
--          modify the target value, if the return value is non-nil, it'll be
--          used as the new value of the target.
--
--              The struct can have one base struct so it will inherit the base
--          struct's validator and initializer, the base struct's validator and
--          initializer should be called before the struct's:
--
--                  struct "Integer" (function(_ENV)
--                      __base = Number
--
--                      local floor = math.floor
--
--                      function Integer(value)
--                          return floor(value) ~= value and "%s must be integer"
--                      end
--                  end)
--
--                  v = Integer(true)  -- Error : the value must be number
--                  v = Integer(1.23)  -- Error : the value must be integer
--
--
-- ii. Member   The member structure represent tables with fixed fields of
--          certain types. Take an example to start:
--
--                  struct "Location" (function(_ENV)
--                      x = Number
--                      y = Number
--                  end)
--
--                  loc = Location{ x = "x" }    -- Error: Usage: Location(x, y) - x must be number
--                  loc = Location(100, 20)
--                  print(loc.x, loc.y)         -- 100  20
--
--              The member sturt can also be used as value constructor(and only
--          the member struct can be used as constructor), the argument order
--          is the same order as the declaration of it members.
--
--              The `x = Number` is the simplest way to declare a member to the
--          struct, but there are other details to be filled in, here is the
--          formal version:
--
--                  struct "Location" (function(_ENV)
--                      member "x" { Type = Number, Require = true }
--                      member "y" { Type = Number, Default = 0    }
--                  end)
--
--                  loc = Location{}            -- Error: Usage: Location(x, y) - x can't be nil
--                  loc = Location(100)
--                  print(loc.x, loc.y)         -- 100  0
--
--              The member is a keyword can only be used in the definition body
--          of a struct, it need a member name and a table contains several
--          settings(the field is case ignored) for the member:
--                  * Type      - The member's type, it could be any enum, struct,
--                      class or interface, also could be 3rd party types that
--                      follow rules(the type's prototype must provide a method
--                      named ValidateValue).
--                  * Require   - Whether the member can't be nil.
--                  * Default   - The default value of the member.
--
--              The member struct also support the validator and initializer :
--
--                  struct "MinMax" (function(_ENV)
--                      member "min" { Type = Number, Require = true }
--                      member "max" { Type = Number, Require = true }
--
--                      function MinMax(val)
--                          return val.min > val.max and "%s.min can't be greater than %s.max"
--                      end
--                  end)
--
--                  v = MinMax(100, 20) -- Error: Usage: MinMax(min, max) - min can't be greater than max
--
--              Since the member struct's value are tables, we also can define
--          struct methods that would be saved to those values:
--
--                  struct "Location" (function(_ENV)
--                      member "x" { Type = Number, Require = true }
--                      member "y" { Type = Number, Default = 0    }
--
--                      function GetRange(val)
--                          return math.sqrt(val.x^2 + val.y^2)
--                      end
--                  end)
--
--                  print(Location(3, 4):GetRange()) -- 5
--
--              We can also declare static methods that can only be used by the
--          struct itself(also for the custom struct):
--
--                  struct "Location" (function(_ENV)
--                      member "x" { Type = Number, Require = true }
--                      member "y" { Type = Number, Default = 0    }
--
--                      __Static__()
--                      function GetRange(val)
--                          return math.sqrt(val.x^2 + val.y^2)
--                      end
--                  end)
--
--                  print(Location.GetRange{x = 3, y = 4}) -- 5
--
--              The `__Static__` is an attribtue, it's used here to declare the
--          next defined method is a static one.
--
--              In the example, we decalre the default value of the member in
--          the member's definition, but we also can provide the default value
--          in the custom struct like :
--
--                  struct "Number" (function(_ENV)
--                      __default = 0
--
--                      function Number(value)
--                          return type(value) ~= "number" and "%s must be number"
--                      end
--                  end)
--
--                  struct "Location" (function(_ENV)
--                      x = Number
--                      y = Number
--                  end)
--
--                  loc = Location()
--                  print(loc.x, loc.y)         -- 0    0
--
--              The member struct can also have base struct, it will inherit
--          members, non-static methods, validator and initializer, but it's
--          not recommended.
--
--iii. Array    The array structure represent tables that contains a list of
--          same type items. Here is an example to decalre an array:
--
--                  struct "Locations" (function(_ENV)
--                      __array = Location
--                  end)
--
--                  v = Locations{ {x = true} } -- Usage: Locations(...) - [1].x must be number
--
--              The array structure also support methods, static methods, base
--          struct, validator and initializer.
--
-- To simplify the definition of the struct, table can be used instead of the
-- function as the definition body.
--
--                  -- Custom struct
--                  struct "Number" {
--                      __default = 0,  -- The default value
--                      -- the function with number index would be used as validator
--                      function (val) return type(val) ~= "number" end,
--                      -- Or you can clearly declare it
--                      __valid = function (val) return type(val) ~= "number" end,
--                  }
--
--                  struct "Boolean" {
--                      __init = function(val) return val and true or false end,
--                  }
--
--                  -- Member struct
--                  struct "Location" {
--                      -- Like use the member keyword, just with a name field
--                      { Name = "x", Type = Number, Require = true },
--                      { Name = "y", Type = Number, Require = true },
--
--                      -- Define methods
--                      GetRange = function(val) return math.sqrt(val.x^2 + val.y^2) end,
--                  }
--
--                  -- Array struct
--                  -- A valid type with number index, also can use the __array as the key
--                  struct "Locations" { Location }
--
-- If a data type's prototype can provide *ValidateValue(type, value)* method,
-- it'd be marked as a value type, the value type can be used in many places,
-- like the member's type, the array's element type, and class's property type.
--
-- The prototype has provided four value type's prototype: enum, struct, class
-- and interface.
--
-- @prototype   struct
-------------------------------------------------------------------------------
do
    -----------------------------------------------------------------------
    --                         attribute targets                         --
    -----------------------------------------------------------------------
    ATTRTAR_STRUCT              = attribute.RegisterTargetType("Struct")
    ATTRTAR_MEMBER              = attribute.RegisterTargetType("Member")
    ATTRTAR_STRUCT_METHOD       = attribute.RegisterTargetType("StructMethod")

    -----------------------------------------------------------------------
    --                          public constants                         --
    -----------------------------------------------------------------------
    STRUCT_TYPE_MEMBER          = "MEMBER"
    STRUCT_TYPE_ARRAY           = "ARRAY"
    STRUCT_TYPE_CUSTOM          = "CUSTOM"

    -----------------------------------------------------------------------
    --                         private constants                         --
    -----------------------------------------------------------------------
    -- FEATURE MODIFIER
    local MOD_SEALED_STRUCT     = 2^0       -- SEALED
    local MOD_IMMUTABLE_STRUCT  = 2^1       -- IMMUTABLE

    -- FIELD INDEX
    local FLD_STRUCT_MOD        = -1        -- FIELD MODIFIER
    local FLD_STRUCT_TYPEMETHOD = -2        -- FIELD OBJECT METHODS
    local FLD_STRUCT_DEFAULT    = -3        -- FEILD DEFAULT
    local FLD_STRUCT_BASE       = -4        -- FIELD BASE STRUCT
    local FLD_STRUCT_VALID      = -5        -- FIELD VALIDATOR
    local FLD_STRUCT_CTOR       = -6        -- FIELD CONSTRUCTOR
    local FLD_STRUCT_NAME       = -7        -- FEILD STRUCT NAME
    local FLD_STRUCT_ERRMSG     = -8        -- FIELD ERROR MESSAGE
    local FLD_STRUCT_VALIDCACHE = -9        -- FIELD VALIDATOR CACHE

    local FLD_STRUCT_ARRAY      =  0        -- FIELD ARRAY ELEMENT
    local FLD_STRUCT_ARRVALID   =  2        -- FIELD ARRAY ELEMENT VALIDATOR
    local FLD_STRUCT_MEMBERSTART=  1        -- FIELD START INDEX OF MEMBER
    local FLD_STRUCT_VALIDSTART =  10000    -- FIELD START INDEX OF VALIDATOR
    local FLD_STRUCT_INITSTART  =  20000    -- FIELD START INDEX OF INITIALIZE

    -- MEMBER FIELD INDEX
    local FLD_MEMBER_OBJ        =  1        -- MEMBER FIELD OBJECT
    local FLD_MEMBER_NAME       =  2        -- MEMBER FIELD NAME
    local FLD_MEMBER_TYPE       =  3        -- MEMBER FIELD TYPE
    local FLD_MEMBER_VALID      =  4        -- MEMBER FIELD TYPE VALIDATOR
    local FLD_MEMBER_DEFAULT    =  5        -- MEMBER FIELD DEFAULT
    local FLD_MEMBER_DEFTFACTORY=  6        -- MEMBER FIELD AS DEFAULT FACTORY
    local FLD_MEMBER_REQUIRE    =  0        -- MEMBER FIELD REQUIRED

    -- TYPE FLAGS
    local FLG_CUSTOM_STRUCT     = 2^0       -- CUSTOM STRUCT FLAG
    local FLG_MEMBER_STRUCT     = 2^1       -- MEMBER STRUCT FLAG
    local FLG_ARRAY_STRUCT      = 2^2       -- ARRAY  STRUCT FLAG
    local FLG_STRUCT_SINGLE_VLD = 2^3       -- SINGLE VALID  FLAG
    local FLG_STRUCT_MULTI_VLD  = 2^4       -- MULTI  VALID  FLAG
    local FLG_STRUCT_SINGLE_INIT= 2^5       -- SINGLE INIT   FLAG
    local FLG_STRUCT_MULTI_INIT = 2^6       -- MULTI  INIT   FLAG
    local FLG_STRUCT_OBJ_METHOD = 2^7       -- OBJECT METHOD FLAG
    local FLG_STRUCT_VALIDCACHE = 2^8       -- VALID  CACHE  FLAG
    local FLG_STRUCT_MULTI_REQ  = 2^9       -- MULTI  FIELD  REQUIRE FLAG
    local FLG_STRUCT_FIRST_TYPE = 2^10      -- FIRST  MEMBER TYPE    FLAG
    local FLG_STRUCT_IMMUTABLE  = 2^11      -- IMMUTABLE     FLAG

    local STRUCT_KEYWORD_ARRAY  = "__array"
    local STRUCT_KEYWORD_BASE   = "__base"
    local STRUCT_KEYWORD_DFLT   = "__default"
    local STRUCT_KEYWORD_INIT   = "__init"
    local STRUCT_KEYWORD_VALD   = "__valid"

    local STRUCT_BUILDER_NEWMTD = "__PLOOP_BD_NEWMTD"

    -----------------------------------------------------------------------
    --                          private storage                          --
    -----------------------------------------------------------------------
    local _StructInfo           = newStorage(WEAK_KEY)
    local _MemberInfo           = newStorage(WEAK_KEY)
    local _DependenceMap        = newStorage(WEAK_KEY)

    -- TYPE BUILDING
    local _StructBuilderInfo    = newStorage(WEAK_KEY)
    local _StructBuilderInDefine= newStorage(WEAK_KEY)

    local _StructValidMap       = {}
    local _StructCtorMap        = {}

    -- Temp
    local _MemberAccessOwner
    local _MemberAccessName

    -----------------------------------------------------------------------
    --                          private helpers                          --
    -----------------------------------------------------------------------
    local getStructTargetInfo   = function (target)
        local info  = _StructBuilderInfo[target]
        if info then return info, true else return _StructInfo[target], false end
    end

    local safeget               = function(self, key) return self[key] end

    local getTypeValueValidate  = function(target)
        local protype = getmetatable(target)
        if protype then
            local ok, ret = pcall(safeget, protype, "ValidateValue")
            return ok and ret
        end
    end

    local setStructBuilderValue = function (self, key, value, stack, notnewindex)
        local owner = environment.GetNameSpace(self)
        if not (owner and _StructBuilderInDefine[self]) then return end

        local tkey  = type(key)
        local tval  = type(value)

        stack       = stack + 1

        if tkey == "string" and not tonumber(key) then
            if key == STRUCT_KEYWORD_DFLT then
                struct.SetDefault(owner, value, stack)
                return true
            elseif tval == "function" then
                if key == STRUCT_KEYWORD_INIT then
                    struct.SetInitializer(owner, value, stack)
                    return true
                elseif key == STRUCT_KEYWORD_VALD or key == namespace.GetNameSpaceName(owner, true) then
                    struct.SetValidator(owner, value, stack)
                    return true
                else
                    struct.AddMethod(owner, key, value, stack)
                    if not notnewindex then
                        -- Those functions should be saved to the builder when the definition is finished
                        local newMethod = rawget(self, STRUCT_BUILDER_NEWMTD)
                        if not newMethod then
                            newMethod   = {}
                            rawset(self, STRUCT_BUILDER_NEWMTD, newMethod)
                        end
                        newMethod[key]  = true
                    end
                    return true
                end
            elseif getTypeValueValidate(value) then
                if key == STRUCT_KEYWORD_ARRAY then
                    struct.SetArrayElement(owner, value, stack)
                    return true
                elseif key == STRUCT_KEYWORD_BASE then
                    struct.SetBaseStruct(owner, value, stack)
                else
                    struct.AddMember(owner, key, { Type = value }, stack)
                end
                return true
            elseif tval == "table" and notnewindex then
                struct.AddMember(owner, key, value, stack)
                return true
            end
        elseif tkey == "number" then
            if tval == "function" then
                struct.SetValidator(owner, value, stack)
                return true
            elseif getTypeValueValidate(value) then
                struct.SetArrayElement(owner, value, stack)
                return true
            elseif tval == "table" then
                struct.AddMember(owner, value, stack)
                return true
            else
                struct.SetDefault(owner, value, stack)
                return true
            end
        end
    end

    -- Update dependence
    local notAllSealedStruct
    notAllSealedStruct          = function (target)
        if target and struct.Validate(target) then
            local info, def     = getStructTargetInfo(target)

            if def or not validateFlags(MOD_SEALED_STRUCT, info[FLD_STRUCT_MOD]) then
                return true
            end

            if info[FLD_STRUCT_ARRAY] then
                return notAllSealedStruct(info[FLD_STRUCT_ARRAY])
            elseif info[FLD_STRUCT_MEMBERSTART] then
                for _, m in ipairs, info, FLD_STRUCT_MEMBERSTART - 1 do
                    if notAllSealedStruct(m) then return true end
                end
            end
        end
    end

    local checkStructDependence = function (target, chkType)
        if target ~= chkType then
            if notAllSealedStruct(chkType) then
                _DependenceMap[chkType]         = _DependenceMap[chkType] or newStorage(WEAK_KEY)
                _DependenceMap[chkType][target] = true
            elseif chkType and _DependenceMap[chkType] then
                _DependenceMap[chkType][target] = nil
                if not next(_DependenceMap[chkType]) then _DependenceMap[chkType] = nil end
            end
        end
    end

    local updateStructDependence= function (target, info)
        info = info or getStructTargetInfo(target)

        if info[FLD_STRUCT_ARRAY] then
            checkStructDependence(target, info[FLD_STRUCT_ARRAY])
        elseif info[FLD_STRUCT_MEMBERSTART] then
            for _, m in ipairs, info, FLD_STRUCT_MEMBERSTART - 1 do
                checkStructDependence(target, m)
            end
        end
    end

    -- Immutable
    local checkStructImmutable  = function(info)
        if info[FLD_STRUCT_INITSTART]  then return false end
        if info[FLD_STRUCT_TYPEMETHOD] then for k, v in pairs, info[FLD_STRUCT_TYPEMETHOD] do if v then return false end end end

        local arrtype = info[FLD_STRUCT_ARRAY]
        if arrtype then
            local isImmutable       = getmetatable(arrtype).IsImmutable
            return isImmutable and isImmutable(arrtype) or false
        elseif info[FLD_STRUCT_MEMBERSTART] then
            for _, m in ipairs, info, FLD_STRUCT_MEMBERSTART - 1 do
                local mtype         = m[FLD_MEMBER_TYPE]
                local isImmutable   = mtype and getmetatable(mtype).IsImmutable
                if not (isImmutable and isImmutable(mtype)) then return false end
            end
        end
        return true
    end

    local updateStructImmutable = function(target, info)
        info = info or getStructTargetInfo(target)
        if checkStructImmutable(info) then
            info[FLD_STRUCT_MOD]= turnOnFlags(MOD_IMMUTABLE_STRUCT, info[FLD_STRUCT_MOD])
        else
            info[FLD_STRUCT_MOD]= turnOffFlags(MOD_IMMUTABLE_STRUCT, info[FLD_STRUCT_MOD])
        end
    end

    -- Cache required
    local checkRepeatStructType
    checkRepeatStructType       = function (target, info)
        if info then
            if info[FLD_STRUCT_ARRAY] then
                if info[FLD_STRUCT_ARRAY] == target then return true end
                return checkRepeatStructType(target, getStructTargetInfo(info[FLD_STRUCT_ARRAY]))
            elseif info[FLD_STRUCT_MEMBERSTART] then
                for _, m in ipairs, info, FLD_STRUCT_MEMBERSTART - 1 do
                    if m == target or checkRepeatStructType(target, getStructTargetInfo(m)) then
                        return true
                    end
                end
            end
        end

        return false
    end

    -- Validator
    local genStructValidator    = function (info)
        local token = 0
        local upval = _Cache()

        if info[FLD_STRUCT_VALIDCACHE] then
            token   = turnOnFlags(FLG_STRUCT_VALIDCACHE, token)
        end

        if info[FLD_STRUCT_MEMBERSTART] then
            token   = turnOnFlags(FLG_MEMBER_STRUCT, token)
            local i = FLD_STRUCT_MEMBERSTART
            while info[i + 1] do i = i + 1 end
            tinsert(upval, i)
        elseif info[FLD_STRUCT_ARRAY] then
            token   = turnOnFlags(FLG_ARRAY_STRUCT, token)
        else
            token   = turnOnFlags(FLG_CUSTOM_STRUCT, token)
        end

        if info[FLD_STRUCT_VALIDSTART] then
            if info[FLD_STRUCT_VALIDSTART + 1] then
                local i = FLD_STRUCT_VALIDSTART + 2
                while info[i] do i = i + 1 end
                token = turnOnFlags(FLG_STRUCT_MULTI_VLD, token)
                tinsert(upval, i - 1)
            else
                token = turnOnFlags(FLG_STRUCT_SINGLE_VLD, token)
            end
        end

        if info[FLD_STRUCT_INITSTART] then
            if info[FLD_STRUCT_INITSTART + 1] then
                local i = FLD_STRUCT_INITSTART + 2
                while info[i] do i = i + 1 end
                token = turnOnFlags(FLG_STRUCT_MULTI_INIT, token)
                tinsert(upval, i - 1)
            else
                token = turnOnFlags(FLG_STRUCT_SINGLE_INIT, token)
            end
        end

        if info[FLD_STRUCT_TYPEMETHOD] then
            for k, v in pairs, info[FLD_STRUCT_TYPEMETHOD] do
                if v then
                    token   = turnOnFlags(FLG_STRUCT_OBJ_METHOD, token)
                    break
                end
            end
        end

        -- Build the validator generator
        if not _StructValidMap[token] then
            local header    = _Cache()
            local body      = _Cache()

            tinsert(body, "")   -- Remain for closure values
            tinsert(body, [[return function(info, value, onlyValid, cache)]])

            if validateFlags(FLG_MEMBER_STRUCT, token) or validateFlags(FLG_ARRAY_STRUCT, token) then
                tinsert(body, [[
                    if type(value)         ~= "table" then return nil, onlyValid or "%s must be a table" end
                    if getmetatable(value) ~= nil     then return nil, onlyValid or "%s must be a table without meta-table" end
                ]])

                if validateFlags(FLG_STRUCT_VALIDCACHE, token) then
                    tinsert(body, [[
                        -- Cache to block recursive validation
                        local vcache = cache[info]
                        if not vcache then
                            vcache = _Cache()
                            cache[info] = vcache
                        elseif vcache[value] then
                            return value
                        end
                        vcache[value]= true
                    ]])
                end
            end

            if validateFlags(FLG_MEMBER_STRUCT, token) then
                tinsert(header, "count")
                tinsert(body, [[
                    if onlyValid then
                        for i = ]] .. FLD_STRUCT_MEMBERSTART .. [[, count do
                            local mem  = info[i]
                            local name = mem[]] .. FLD_MEMBER_NAME .. [[]
                            local vtype= mem[]] .. FLD_MEMBER_TYPE ..[[]
                            local val  = value[name]
                            local msg

                            if val == nil then
                                if mem[]] .. FLD_MEMBER_REQUIRE .. [[] then
                                    return nil, true
                                end
                            elseif vtype then
                                val, msg = mem[]] .. FLD_MEMBER_VALID .. [[](vtype, val, true, cache)
                                if msg then return nil, true end
                            end
                        end
                    else
                        for i = ]] .. FLD_STRUCT_MEMBERSTART .. [[, count do
                            local mem  = info[i]
                            local name = mem[]] .. FLD_MEMBER_NAME .. [[]
                            local vtype= mem[]] .. FLD_MEMBER_TYPE ..[[]
                            local val  = value[name]
                            local msg

                            if val == nil then
                                if mem[]] .. FLD_MEMBER_REQUIRE .. [[] then
                                    return nil, strformat("%s.%s can't be nil", "%s", name)
                                end

                                if mem[]] .. FLD_MEMBER_DEFTFACTORY .. [[] then
                                    val= mem[]] .. FLD_MEMBER_DEFAULT .. [[](value)
                                else
                                    val= clone(mem[]] .. FLD_MEMBER_DEFAULT .. [[], true)
                                end
                            elseif vtype then
                                val, msg = mem[]] .. FLD_MEMBER_VALID .. [[](vtype, val, false, cache)
                                if msg then return nil, type(msg) == "string" and strgsub(msg, "%%s", "%%s" .. "." .. name) or strformat("%s.%s must be [%s]", "%s", name, tostring(vtype)) end
                            end

                            value[name] = val
                        end
                    end
                ]])
            elseif validateFlags(FLG_ARRAY_STRUCT, token) then
                tinsert(body, [[
                    local array = info[]] .. FLD_STRUCT_ARRAY .. [[]
                    local avalid= info[]] .. FLD_STRUCT_ARRVALID .. [[]
                    if onlyValid then
                        for i, v in ipairs, value, 0 do
                            local ret, msg  = avalid(array, v, true, cache)
                            if msg then return nil, true end
                        end
                    else
                        for i, v in ipairs, value, 0 do
                            local ret, msg  = avalid(array, v, false, cache)
                            if msg then return nil, type(msg) == "string" and strgsub(msg, "%%s", "%%s[" .. i .. "]") or strformat("%s[%s] must be [%s]", "%s", i, tostring(array)) end
                            value[i] = ret
                        end
                    end
                ]])
            end

            if validateFlags(FLG_STRUCT_SINGLE_VLD, token) then
                tinsert(body, [[
                    local msg = info[]] .. FLD_STRUCT_VALIDSTART .. [[](value)
                    if msg then return nil, onlyValid or type(msg) == "string" and msg or strformat("%s must be [%s]", "%s", info[]] .. FLD_STRUCT_NAME .. [[]) end
                ]])
            elseif validateFlags(FLG_STRUCT_MULTI_VLD, token) then
                tinsert(header, "mvalid")
                tinsert(body, [[
                    for i = ]] .. FLD_STRUCT_VALIDSTART .. [[, mvalid do
                        local msg = info[i](value)
                        if msg then return nil, onlyValid or type(msg) == "string" and msg or strformat("%s must be [%s]", "%s", info[]] .. FLD_STRUCT_NAME .. [[]) end
                    end
                ]])
            end

            if validateFlags(FLG_STRUCT_SINGLE_INIT, token) or validateFlags(FLG_STRUCT_MULTI_INIT, token) or validateFlags(FLG_STRUCT_OBJ_METHOD, token) then
                tinsert(body, [[if onlyValid then return value end]])
            end

            if validateFlags(FLG_STRUCT_SINGLE_INIT, token) or validateFlags(FLG_STRUCT_MULTI_INIT, token) then
                if validateFlags(FLG_STRUCT_SINGLE_INIT, token) then
                    tinsert(body, [[
                        local ret = info[]] .. FLD_STRUCT_INITSTART .. [[](value)
                    ]])

                    if validateFlags(FLG_CUSTOM_STRUCT, token) then
                        tinsert(body, [[if ret ~= nil then value = ret end]])
                    end
                else
                    tinsert(header, "minit")
                    tinsert(body, [[
                        for i = ]] .. FLD_STRUCT_INITSTART .. [[, minit do
                            local ret = info[i](value)
                        ]])
                    if validateFlags(FLG_CUSTOM_STRUCT, token) then
                        tinsert(body, [[if ret ~= nil then value = ret end]])
                    end
                    tinsert(body, [[end]])
                end
            end

            if validateFlags(FLG_STRUCT_OBJ_METHOD, token) then
                if validateFlags(FLG_CUSTOM_STRUCT, token) then
                    tinsert(body, [[if type(value) == "table" then]])
                end

                tinsert(body, [[
                    for k, v in pairs, info[]] .. FLD_STRUCT_TYPEMETHOD .. [[] do
                        if v and value[k] == nil then value[k] = v end
                    end
                ]])

                if validateFlags(FLG_CUSTOM_STRUCT, token) then
                    tinsert(body, [[end]])
                end
            end

            tinsert(body, [[
                    return value
                end
            ]])

            if #header > 0 then
                body[1] = "local " .. tblconcat(header, ",") .. "= ..."
            end

            _StructValidMap[token] = loadSnippet(tblconcat(body, "\n"), "Struct_Validate_" .. token)

            if #header == 0 then
                _StructValidMap[token] = _StructValidMap[token]()
            end

            _Cache(header)
            _Cache(body)
        end

        if #upval > 0 then
            info[FLD_STRUCT_VALID] = _StructValidMap[token](unpack(upval))
        else
            info[FLD_STRUCT_VALID] = _StructValidMap[token]
        end

        _Cache(upval)
    end

    -- Ctor
    local genStructConstructor  = function (info)
        local token = 0
        local upval = _Cache()

        if info[FLD_STRUCT_VALIDCACHE] then
            token   = turnOnFlags(FLG_STRUCT_VALIDCACHE, token)
        end

        if info[FLD_STRUCT_MEMBERSTART] then
            token   = turnOnFlags(FLG_MEMBER_STRUCT, token)
            local i = FLD_STRUCT_MEMBERSTART + 1
            local r = false
            while info[i] do
                if not r and info[i][FLD_MEMBER_REQUIRE] then r = true end
                i = i + 1
            end
            tinsert(upval, i - 1)
            if r then
                token = turnOnFlags(FLG_STRUCT_MULTI_REQ, token)
            else
                local ftype = info[FLD_STRUCT_MEMBERSTART][FLD_MEMBER_TYPE]
                if ftype then
                    token = turnOnFlags(FLG_STRUCT_FIRST_TYPE, token)
                    tinsert(upval, ftype)
                    tinsert(upval, info[FLD_STRUCT_MEMBERSTART][FLD_MEMBER_VALID])
                    local isImmutable = getmetatable(ftype).IsImmutable
                    tinsert(upval, isImmutable and isImmutable(ftype) or false)
                end
            end
        elseif info[FLD_STRUCT_ARRAY] then
            token   = turnOnFlags(FLG_ARRAY_STRUCT, token)
        else
            token   = turnOnFlags(FLG_CUSTOM_STRUCT, token)
        end

        if validateFlags(MOD_IMMUTABLE_STRUCT, info[FLD_STRUCT_MOD]) then
            token           = turnOnFlags(FLG_STRUCT_IMMUTABLE, token)
        end

        -- Build the validator generator
        if not _StructCtorMap[token] then
            local header    = _Cache()
            local body      = _Cache()

            tinsert(body, "")

            if validateFlags(FLG_MEMBER_STRUCT, token) then
                tinsert(body, [[
                    return function(info, first, ...)
                        local ivalid = info[]].. FLD_STRUCT_VALID .. [[]
                        local ret, msg
                        if select("#", ...) == 0 and type(first) == "table" and getmetatable(first) == nil then
                ]])

                tinsert(header, "count")
                if not validateFlags(FLG_STRUCT_MULTI_REQ, token) then
                    -- So, it may be the first member
                    if validateFlags(FLG_STRUCT_FIRST_TYPE, token) then
                        tinsert(header, "ftype")
                        tinsert(header, "fvalid")
                        tinsert(header, "fimtbl")
                        tinsert(body, [[
                            local _, fmatch = fvalid(ftype, first, true) fmatch = not fmatch
                        ]])
                    else
                        tinsert(body, [[local fmatch, fimtbl = true, true]])
                    end
                else
                    tinsert(body, [[local fmatch, fimtbl = false, false]])
                end

                if validateFlags(FLG_STRUCT_VALIDCACHE, token) then
                    tinsert(body, [[
                        local cache = _Cache()
                        ret, msg    = ivalid(info, first, fmatch and not fimtbl, cache)
                        for k, v in pairs, cache do cache[k] = nil _Cache(v) end _Cache(cache)
                    ]])
                else
                    tinsert(body, [[ret, msg = ivalid(info, first, fmatch and not fimtbl)]])
                end

                tinsert(body, [[if not msg then]])

                if not validateFlags(FLG_STRUCT_IMMUTABLE, token) then
                    tinsert(body, [[if fmatch and not fimtbl then]])

                    if validateFlags(FLG_STRUCT_VALIDCACHE, token) then
                        tinsert(body, [[
                            local cache = _Cache()
                            ret, msg = ivalid(info, first, false, cache)
                            for k, v in pairs, cache do cache[k] = nil _Cache(v) end _Cache(cache)
                        ]])
                    else
                        tinsert(body, [[ret, msg = ivalid(info, first, false)]])
                    end

                    tinsert(body, [[end]])
                end

                tinsert(body, [[
                            return ret
                        elseif not fmatch then
                            error(info[]] .. FLD_STRUCT_ERRMSG .. [[] .. (type(msg) == "string" and strgsub(msg, "%%s%.?", "") or "the value is not valid."), 3)
                        end
                    end
                ]])
            else
                tinsert(body, [[
                    return function(info, ret)
                        local ivalid = info[]].. FLD_STRUCT_VALID .. [[]
                        local msg
                ]])
            end

            if validateFlags(FLG_MEMBER_STRUCT, token) then
                tinsert(body, [[
                    ret = {}
                    local j = 1
                    ret[ info[]] .. FLD_STRUCT_MEMBERSTART .. [[][]] .. FLD_MEMBER_NAME .. [[] ] = first
                    for i = ]] .. (FLD_STRUCT_MEMBERSTART + 1) .. [[, count do
                        ret[ info[i][]] .. FLD_MEMBER_NAME .. [[] ] = (select(j, ...))
                        j = j + 1
                    end
                ]])
            end

            if validateFlags(FLG_STRUCT_VALIDCACHE, token) then
                tinsert(body, [[
                    local cache = _Cache()
                    ret, msg = ivalid(info, ret, false, cache)
                    for k, v in pairs, cache do cache[k] = nil _Cache(v) end _Cache(cache)
                ]])
            else
                tinsert(body, [[
                    ret, msg = ivalid(info, ret, false)
                ]])
            end

            tinsert(body, [[if not msg then return ret end]])

            if validateFlags(FLG_MEMBER_STRUCT, token) or validateFlags(FLG_ARRAY_STRUCT, token) then
                tinsert(body, [[
                    error(info[]] .. FLD_STRUCT_ERRMSG .. [[] .. (type(msg) == "string" and strgsub(msg, "%%s%.?", "") or "the value is not valid."), 3)
                ]])
            else
                tinsert(body, [[
                    error(strgsub(msg, "%%s", "the value"), 3)
                ]])
            end

            tinsert(body, [[end]])

            if #header > 0 then
                body[1] = "local " .. tblconcat(header, ",") .. "= ..."
            end

            _StructCtorMap[token] = loadSnippet(tblconcat(body, "\n"), "Struct_Ctor_" .. token)

            if #header == 0 then
                _StructCtorMap[token] = _StructCtorMap[token]()
            end

            _Cache(header)
            _Cache(body)
        end

        if #upval > 0 then
            info[FLD_STRUCT_CTOR] = _StructCtorMap[token](unpack(upval))
        else
            info[FLD_STRUCT_CTOR] = _StructCtorMap[token]
        end

        _Cache(upval)
    end

    -- Refresh Depends
    local updateStructDepends   = function (target, cache)
        local map = _DependenceMap[target]

        if map then
            _DependenceMap[target] = nil

            for t in pairs, map do
                if not cache[t] then
                    cache[t] = true

                    local info, def = getStructTargetInfo(t)
                    if not def then
                        info[FLD_STRUCT_VALIDCACHE] = checkRepeatStructType(t, info)

                        updateStructDependence(t, info)
                        updateStructImmutable (t, info)

                        genStructValidator  (info)
                        genStructConstructor(info)

                        updateStructDepends (t, cache)
                    end
                end
            end

            _Cache(map)
        end
    end

    -----------------------------------------------------------------------
    --                             prototype                             --
    -----------------------------------------------------------------------
    struct                      = prototype {
        __tostring              = "struct",
        __index                 = {
            --- Add a member to the structure
            -- @static
            -- @method  AddMember
            -- @owner   struct
            -- @format  (structure[, name], definition[, stack])
            -- @param   structure       the structure
            -- @param   name            the member's name
            -- @param   definition      the member's definition like { type = [Value type], default = [value], require = [boolean], name = [string] }
            -- @param   stack           the stack level
            ["AddMember"]       = function(target, name, definition, stack)
                local info, def = getStructTargetInfo(target)

                if type(name) == "table" then
                    definition, stack, name = name, definition, nil
                    for k, v in pairs, definition do
                        if type(k) == "string" and strlower(k) == "name" and type(v) == "string" and not tonumber(v) then
                            name, definition[k] = v, nil
                            break
                        end
                    end
                end
                stack = (type(stack) == "number" and stack or 1) + 1

                if info then
                    if not def then error(strformat("Usage: struct.AddMember(structure[, name], definition[, stack]) - The %s's definition is finished", tostring(target)), stack) end
                    if type(name) ~= "string" then error("Usage: struct.AddMember(structure[, name], definition[, stack]) - The name must be a string", stack) end
                    name = strtrim(name)
                    if name == "" then error("Usage: struct.AddMember(structure[, name], definition[, stack]) - The name can't be empty", stack) end
                    if type(definition) ~= "table" then error("Usage: struct.AddMember(structure[, name], definition[, stack]) - The definition is missing", stack) end
                    if info[FLD_STRUCT_ARRAY] then error("Usage: struct.AddMember(structure[, name], definition[, stack]) - The structure is an array structure, can't add member", stack) end

                    local idx = FLD_STRUCT_MEMBERSTART
                    while info[idx] do
                        if info[idx][FLD_MEMBER_NAME] == name then
                            error(strformat("Usage: struct.AddMember(structure[, name], definition[, stack]) - There is an existed member with the name : %q", name), stack)
                        end
                        idx = idx + 1
                    end

                    local mobj  = prototype.NewProxy(member)
                    local minfo = _Cache()
                    _MemberInfo = saveStorage(_MemberInfo, mobj, minfo)
                    minfo[FLD_MEMBER_OBJ]   = mobj
                    minfo[FLD_MEMBER_NAME]  = name

                    -- Save attributes
                    attribute.SaveAttributes(mobj, ATTRTAR_MEMBER, stack + 1)

                    -- Inherit attributes
                    if info[FLD_STRUCT_BASE] then
                        local smem  = struct.GetMember(info[FLD_STRUCT_BASE], name)
                        if smem  then attribute.InheritAttributes(mobj, ATTRTAR_MEMBER, smem) end
                    end

                    -- Init the definition with attributes
                    definition = attribute.InitDefinition(mobj, ATTRTAR_MEMBER, definition, target, name)

                    -- Parse the definition
                    for k, v in pairs, definition do
                        if type(k) == "string" then
                            k = strlower(k)

                            if k == "type" then
                                local tpValid = getTypeValueValidate(v)

                                if tpValid then
                                    minfo[FLD_MEMBER_TYPE]  = v
                                    minfo[FLD_MEMBER_VALID] = tpValid
                                else
                                    error("Usage: struct.AddMember(structure[, name], definition[, stack]) - The member's type is not valid", stack)
                                end
                            elseif k == "require" and v then
                                minfo[FLD_MEMBER_REQUIRE]   = true
                            elseif k == "default" then
                                minfo[FLD_MEMBER_DEFAULT]   = v
                            end
                        end
                    end

                    if minfo[FLD_MEMBER_REQUIRE] then
                        minfo[FLD_MEMBER_DEFAULT] = nil
                    elseif minfo[FLD_MEMBER_TYPE] then
                        if minfo[FLD_MEMBER_DEFAULT] ~= nil then
                            local ret, msg  = minfo[FLD_MEMBER_VALID](minfo[FLD_MEMBER_TYPE], minfo[FLD_MEMBER_DEFAULT])
                            if not msg then
                                minfo[FLD_MEMBER_DEFAULT]       = ret
                            elseif type(minfo[FLD_MEMBER_DEFAULT]) == "function" then
                                minfo[FLD_MEMBER_DEFTFACTORY]   = true
                            else
                                error("Usage: struct.AddMember(structure[, name], definition[, stack]) - The default value is not valid", stack)
                            end
                        end
                        if minfo[FLD_MEMBER_DEFAULT] == nil then
                            local getDefault            = getmetatable(minfo[FLD_MEMBER_TYPE]).GetDefault
                            minfo[FLD_MEMBER_DEFAULT]   = getDefault and getDefault(minfo[FLD_MEMBER_TYPE])
                        end
                    end

                    info[idx] = minfo
                    attribute.ApplyAttributes (mobj, ATTRTAR_MEMBER, target, name)
                    attribute.AttachAttributes(mobj, ATTRTAR_MEMBER, target, name)
                else
                    error("Usage: struct.AddMember(structure[, name], definition[, stack]) - The structure is not valid", stack)
                end
            end;

            --- Add an object method to the structure
            -- @static
            -- @method  AddMethod
            -- @owner   struct
            -- @format  (structure, name, func[, stack])
            -- @param   structure       the structure
            -- @param   name            the method'a name
            -- @param   func            the method's definition
            -- @param   stack           the stack level
            ["AddMethod"]       = function(target, name, func, stack)
                local info, def = getStructTargetInfo(target)
                stack = (type(stack) == "number" and stack or 1) + 1

                if info then
                    if not def then error(strformat("Usage: struct.AddMethod(structure, name, func[, stack]) - The %s's definition is finished", tostring(target)), stack) end
                    if type(name) ~= "string" then error("Usage: struct.AddMethod(structure, name, func[, stack]) - The name must be a string", stack) end
                    name = strtrim(name)
                    if name == "" then error("Usage: Usage: struct.AddMethod(structure, name, func[, stack]) - The name can't be empty", stack) end
                    if type(func) ~= "function" then error("Usage: struct.AddMethod(structure, name, func[, stack]) - The func must be a function", stack) end

                    attribute.SaveAttributes(func, ATTRTAR_STRUCT_METHOD, stack)

                    if info[FLD_STRUCT_BASE] and not info[name] then
                        local sfunc = struct.GetObjectMethod(info[FLD_STRUCT_BASE], name)
                        if sfunc then attribute.InheritAttributes(func, ATTRTAR_STRUCT_METHOD, sfunc) end
                    end

                    local ret = attribute.InitDefinition(func, ATTRTAR_STRUCT_METHOD, func, target, name)
                    if ret ~= func then attribute.ToggleTarget(func, ret) func = ret end

                    if not info[name] then
                        info[FLD_STRUCT_TYPEMETHOD]         = info[FLD_STRUCT_TYPEMETHOD] or _Cache()
                        info[FLD_STRUCT_TYPEMETHOD][name]   = func
                    else
                        info[name]  = func
                    end

                    attribute.ApplyAttributes (func, ATTRTAR_STRUCT_METHOD, target, name)
                    attribute.AttachAttributes(func, ATTRTAR_STRUCT_METHOD, target, name)
                else
                    error("Usage: struct.AddMethod(structure, name, func[, stack]) - The structure is not valid", stack)
                end
            end;

            --- Begin the structure's definition
            -- @static
            -- @method  BeginDefinition
            -- @owner   struct
            -- @format  (structure[, stack])
            -- @param   structure       the structure
            -- @param   stack           the stack level
            ["BeginDefinition"] = function(target, stack)
                stack = (type(stack) == "number" and stack or 1) + 1

                target          = struct.Validate(target)
                if not target then error("Usage: struct.BeginDefinition(structure[, stack]) - The structure not existed", stack) end

                local info      = _StructInfo[target]

                if info and validateFlags(MOD_SEALED_STRUCT, info[FLD_STRUCT_MOD]) then error(strformat("Usage: struct.BeginDefinition(structure[, stack]) - The %s is sealed, can't be re-defined", tostring(target)), stack) end
                if _StructBuilderInfo[target] then error(strformat("Usage: struct.BeginDefinition(structure[, stack]) - The %s's definition has already begun", tostring(target)), stack) end

                _StructBuilderInfo      = saveStorage(_StructBuilderInfo, target, {
                    [FLD_STRUCT_MOD ]   = 0,
                    [FLD_STRUCT_NAME]   = tostring(target),
                })

                attribute.SaveAttributes(target, ATTRTAR_STRUCT, stack)
            end;

            --- End the structure's definition
            -- @static
            -- @method  EndDefinition
            -- @owner   struct
            -- @format  (structure[, stack])
            -- @param   structure       the structure
            -- @param   stack           the stack level
            ["EndDefinition"]   = function(target, stack)
                local ninfo     = _StructBuilderInfo[target]
                if not ninfo then return end

                stack = (type(stack) == "number" and stack or 1) + 1

                attribute.ApplyAttributes(target, ATTRTAR_STRUCT)

                _StructBuilderInfo  = saveStorage(_StructBuilderInfo, target, nil)

                -- Install base struct's features
                if ninfo[FLD_STRUCT_BASE] then
                    -- Check conflict, some should be handled by the author
                    local binfo = _StructInfo[ninfo[FLD_STRUCT_BASE]]

                    if ninfo[FLD_STRUCT_ARRAY] then             -- Array
                        if not binfo[FLD_STRUCT_ARRAY] then
                            error(strformat("Usage: struct.EndDefinition(structure[, stack]) - The %s's base struct isn't an array structure", tostring(target)), stack)
                        end
                    elseif ninfo[FLD_STRUCT_MEMBERSTART] then   -- Member
                        if binfo[FLD_STRUCT_ARRAY] then
                            error(strformat("Usage: struct.EndDefinition(structure[, stack]) - The %s's base struct can't be an array structure", tostring(target)), stack)
                        elseif binfo[FLD_STRUCT_MEMBERSTART] then
                            -- Try to keep the base struct's member order
                            local cache     = _Cache()
                            local idx       = FLD_STRUCT_MEMBERSTART
                            while ninfo[idx] do
                                tinsert(cache, ninfo[idx])
                                idx         = idx + 1
                            end

                            local memCnt    = #cache

                            idx             = FLD_STRUCT_MEMBERSTART
                            while binfo[idx] do
                                local name  = binfo[idx][FLD_MEMBER_NAME]
                                ninfo[idx]  = binfo[idx]

                                for k, v in pairs, cache do
                                    if name == v[FLD_MEMBER_NAME] then
                                        ninfo[idx]  = v
                                        cache[k]    = nil
                                        break
                                    end
                                end

                                idx         = idx + 1
                            end

                            for i = 1, memCnt do
                                if cache[i] then
                                    ninfo[idx]      = cache[i]
                                    idx             = idx + 1
                                end
                            end

                            _Cache(cache)
                        end
                    else                                        -- Custom
                        if binfo[FLD_STRUCT_ARRAY] then
                            ninfo[FLD_STRUCT_ARRAY] = binfo[FLD_STRUCT_ARRAY]
                            ninfo[FLD_STRUCT_ARRVALID]= binfo[FLD_STRUCT_ARRVALID]
                        elseif binfo[FLD_STRUCT_MEMBERSTART] then
                            -- Share members
                            local idx = FLD_STRUCT_MEMBERSTART
                            while binfo[idx] do
                                ninfo[idx]  = binfo[idx]
                                idx         = idx + 1
                            end
                        end
                    end

                    -- Clone the validator and Initializer
                    local nvalid    = ninfo[FLD_STRUCT_VALIDSTART]
                    local ninit     = ninfo[FLD_STRUCT_INITSTART]

                    local idx       = FLD_STRUCT_VALIDSTART
                    while binfo[idx] do
                        ninfo[idx]  = binfo[idx]
                        idx         = idx + 1
                    end
                    ninfo[idx]      = nvalid

                    idx             = FLD_STRUCT_INITSTART
                    while binfo[idx] do
                        ninfo[idx]  = binfo[idx]
                        idx         = idx + 1
                    end
                    ninfo[idx]      = ninit

                    -- Clone the methods
                    if binfo[FLD_STRUCT_TYPEMETHOD] then
                        nobjmtd     = ninfo[FLD_STRUCT_TYPEMETHOD] or _Cache()

                        for k, v in pairs, binfo[FLD_STRUCT_TYPEMETHOD] do
                            if v and nobjmtd[k] == nil then
                                nobjmtd[k]  = v
                            end
                        end

                        if next(nobjmtd) then
                            ninfo[FLD_STRUCT_TYPEMETHOD] = nobjmtd
                        else
                            ninfo[FLD_STRUCT_TYPEMETHOD] = nil
                            _Cache(nobjmtd)
                        end
                    end
                end

                -- Generate error message
                if ninfo[FLD_STRUCT_MEMBERSTART] then
                    local args      = _Cache()
                    local idx       = FLD_STRUCT_MEMBERSTART
                    while ninfo[idx] do
                        tinsert(args, ninfo[idx][FLD_MEMBER_NAME])
                        idx         = idx + 1
                    end
                    ninfo[FLD_STRUCT_ERRMSG]    = strformat("Usage: %s(%s) - ", tostring(target), tblconcat(args, ", "))
                    _Cache(args)
                elseif ninfo[FLD_STRUCT_ARRAY] then
                    ninfo[FLD_STRUCT_ERRMSG]    = strformat("Usage: %s(...) - ", tostring(target))
                else
                    ninfo[FLD_STRUCT_ERRMSG]    = strformat("[%s]", tostring(target))
                end

                ninfo[FLD_STRUCT_VALIDCACHE]    = checkRepeatStructType(target, ninfo)

                updateStructDependence(target, ninfo)
                updateStructImmutable(target, ninfo)

                genStructValidator(ninfo)
                genStructConstructor(ninfo)

                -- Check the default value is it's custom struct
                if ninfo[FLD_STRUCT_DEFAULT] ~= nil then
                    local deft      = ninfo[FLD_STRUCT_DEFAULT]
                    ninfo[FLD_STRUCT_DEFAULT]  = nil

                    if not ninfo[FLD_STRUCT_ARRAY] and not ninfo[FLD_STRUCT_MEMBERSTART] then
                        local ret, msg = struct.ValidateValue(target, deft)
                        if not msg then ninfo[FLD_STRUCT_DEFAULT] = ret end
                    end
                end

                -- Save as new structure's info
                _StructInfo     = saveStorage(_StructInfo, target, ninfo)

                attribute.AttachAttributes(target, ATTRTAR_STRUCT)

                -- Refresh structs depended on this
                if _DependenceMap[target] then
                    local cache = _Cache()
                    cache[target] = true
                    updateStructDepends(target, cache)
                    _Cache(cache)
                end

                return target
            end;

            --- Get the array structure's element type
            -- @static
            -- @method  GetArrayElement
            -- @owner   struct
            -- @param   structure       the structure
            -- @return  type            the array element's type
            ["GetArrayElement"] = function(target)
                local info      = getStructTargetInfo(target)
                return info and info[FLD_STRUCT_ARRAY]
            end;

            --- Get the structure's base struct type
            -- @static
            -- @method  GetBaseStruct
            -- @owner   struct
            -- @param   structure       the structure
            -- @return  type            the base struct
            ["GetBaseStruct"]   = function(target)
                local info      = getStructTargetInfo(target)
                return info and info[FLD_STRUCT_BASE]
            end;

            --- Get the custom structure's default value
            -- @static
            -- @method  GetDefault
            -- @owner   struct
            -- @param   structure       the structure
            -- @return  value           the default value
            ["GetDefault"]      = function(target)
                local info      = getStructTargetInfo(target)
                return info and info[FLD_STRUCT_DEFAULT]
            end;

            --- Get the member of the structure with given name
            -- @static
            -- @method  GetMember
            -- @owner   struct
            -- @param   structure       the structure
            -- @param   name            the member's name
            -- @return  member          the member
            ["GetMember"]       = function(target, name)
                local info      = getStructTargetInfo(target)
                if info then
                    for _, m in ipairs, info, FLD_STRUCT_MEMBERSTART - 1 do
                        if m[FLD_MEMBER_NAME] == name then
                            return m[FLD_MEMBER_OBJ]
                        end
                    end
                end
            end;

            --- Get the members of the structure
            -- @static
            -- @method  GetMembers
            -- @owner   struct
            -- @format  (structure[, cache])
            -- @param   structure       the structure
            -- @param   cache           the table used to save the result
            -- @rformat (cache)         the cache that contains the member list
            -- @rformat (iter, struct)  without the cache parameter, used in generic for
            ["GetMembers"]      = function(target, cache)
                local info      = getStructTargetInfo(target)
                if info then
                    if cache then
                        cache   = type(cache) == "table" and wipe(cache) or {}
                        for _, m in ipairs, info, FLD_STRUCT_MEMBERSTART - 1 do
                            tinsert(cache, m[FLD_MEMBER_OBJ])
                        end
                        return cache
                    else
                        return function(self, i)
                            i   = i and (i + 1) or FLD_STRUCT_MEMBERSTART
                            if info[i] then
                                return i, info[i][FLD_MEMBER_OBJ]
                            end
                        end, target
                    end
                end
                if cache then
                    return type(cache) == "table" and cache or nil
                else
                    return fakefunc, target
                end
            end;

            --- Get the method of the structure with given name
            -- @static
            -- @method  GetMethod
            -- @owner   struct
            -- @param   structure       the structure
            -- @param   name            the method's name
            -- @return  function        the method
            ["GetMethod"]       = function(target, name)
                local info, def = getStructTargetInfo(target)
                return info and type(name) == "string" and (info[name] or info[FLD_STRUCT_TYPEMETHOD] and info[FLD_STRUCT_TYPEMETHOD][name]) or nil
            end;

            --- Get the object method of the structure with given name
            -- @static
            -- @method  GetObjectMethod
            -- @owner   struct
            -- @param   structure       the structure
            -- @param   name            the method's name
            -- @return  function        the method
            ["GetObjectMethod"] = function(target, name)
                local info      = getStructTargetInfo(target)
                return info and type(name) == "string" and info[FLD_STRUCT_TYPEMETHOD] and info[FLD_STRUCT_TYPEMETHOD][name] or nil
            end;

            --- Get the static method of the structure with given name
            -- @static
            -- @method  GetStaticMethod
            -- @owner   struct
            -- @param   structure       the structure
            -- @param   name            the method's name
            -- @return  function        the method
            ["GetStaticMethod"] = function(target, name)
                local info      = getStructTargetInfo(target)
                return info and type(name) == "string" and info[name] or nil
            end;

            --- Get all the methods of the structure
            -- @static
            -- @method  GetMethods
            -- @owner   struct
            -- @format  (structure[, cache])
            -- @param   structure       the structure
            -- @param   cache           the table used to save the result
            -- @rformat (cache)         the cache that contains the method list
            -- @rformat (iter, struct)  without the cache parameter, used in generic for
            ["GetMethods"]      = function(target, cache)
                local info      = getStructTargetInfo(target)
                if info then
                    local objm  = info[FLD_STRUCT_TYPEMETHOD]
                    if cache then
                        cache   = type(cache) == "table" and wipe(cache) or {}
                        if objm then for k, v in pairs, objm do cache[k] = v or info[k] end end
                        return cache
                    elseif objm then
                        return function(self, n)
                            local m, v = next(objm, n)
                            if m then return m, v or info[m] end
                        end, target
                    end
                end
                if cache then
                    return type(cache) == "table" and cache or nil
                else
                    return fakefunc, target
                end
            end;

            --- Get all the object methods of the structure
            -- @static
            -- @method  GetObjectMethods
            -- @owner   struct
            -- @format  (structure[, cache])
            -- @param   structure       the structure
            -- @param   cache           the table used to save the result
            -- @rformat (cache)         the cache that contains the method list
            -- @rformat (iter, struct)  without the cache parameter, used in generic for
            ["GetObjectMethods"]= function(target, cache)
                local info      = getStructTargetInfo(target)
                if info then
                    local objm  = info[FLD_STRUCT_TYPEMETHOD]
                    if cache then
                        cache   = type(cache) == "table" and wipe(cache) or {}
                        for k, v in pairs, objm do if v then cache[k] = v end end
                        return cache
                    elseif objm then
                        return function(self, n)
                            local m, v = next(objm, n)
                            while m and not v do m, v = next(objm, m) end
                            return m, v
                        end, target
                    end
                end
                if cache then
                    return type(cache) == "table" and cache or nil
                else
                    return fakefunc, target
                end
            end;

            --- Get all the static methods of the structure
            -- @static
            -- @method  GetObjectMethods
            -- @owner   struct
            -- @format  (structure[, cache])
            -- @param   structure       the structure
            -- @param   cache           the table used to save the result
            -- @rformat (cache)         the cache that contains the method list
            -- @rformat (iter, struct)  without the cache parameter, used in generic for
            ["GetStaticMethods"]= function(target, cache)
                local info      = getStructTargetInfo(target)
                if info then
                    local objm  = info[FLD_STRUCT_TYPEMETHOD]
                    if cache then
                        cache   = type(cache) == "table" and wipe(cache) or {}
                        for k, v in pairs, objm do if not v then cache[k] = info[k] end end
                        return cache
                    elseif objm then
                        return function(self, n)
                            local m, v = next(objm, n)
                            while m and v do m, v = next(objm, m) end
                            if m then return m, info[m] end
                        end, target
                    end
                end
                if cache then
                    return type(cache) == "table" and cache or nil
                else
                    return fakefunc, target
                end
            end;

            --- Get the struct type of the structure
            -- @static
            -- @method  GetStructType
            -- @owner   struct
            -- @param   structure       the structure
            -- @return  string          the structure's type: CUSTOM|ARRAY|MEMBER
            ["GetStructType"]   = function(target)
                local info      = getStructTargetInfo(target)
                if info then
                    if info[FLD_STRUCT_ARRAY] then return STRUCT_TYPE_ARRAY end
                    if info[FLD_STRUCT_MEMBERSTART] then return STRUCT_TYPE_MEMBER end
                    return STRUCT_TYPE_CUSTOM
                end
            end;

            --- Whether the struct's value is immutable through the validation, means no object method, no initializer
            -- @static
            -- @method  IsImmutable
            -- @owner   struct
            -- @param   structure       the structure
            -- @return  boolean         true if the value should be immutable
            ["IsImmutable"]     = function(target)
                local info      = getStructTargetInfo(target)
                return info and validateFlags(MOD_IMMUTABLE_STRUCT, info[FLD_STRUCT_MOD]) or false
            end;

            --- Whether a structure use the other as its base structure
            -- @static
            -- @method  IsSubType
            -- @owner   struct
            -- @param   structure       the structure
            -- @param   base            the base structure
            -- @return  boolean         true if the structure use the target structure as base
            ["IsSubType"]       = function(target, base)
                if struct.Validate(base) then
                    while target do
                        if target == base then return true end
                        local i = getStructTargetInfo(target)
                        target  = i and i[FLD_STRUCT_BASE]
                    end
                end
                return false
            end;

            --- Whether the structure is sealed, can't be re-defined
            -- @static
            -- @method  IsSealed
            -- @owner   struct
            -- @param   structure       the structure
            -- @return  boolean         true if the structure is sealed
            ["IsSealed"]        = function(target)
                local info      = getStructTargetInfo(target)
                return info and validateFlags(MOD_SEALED_STRUCT, info[FLD_STRUCT_MOD]) or false
            end;

            --- Whether the structure's given name method is static
            -- @static
            -- @method  IsStaticMethod
            -- @owner   struct
            -- @param   structure       the structure
            -- @param   name            the method's name
            -- @return  boolean         true if the method is static
            ["IsStaticMethod"]  = function(target, name)
                local info      = getStructTargetInfo(target)
                return info and type(name) == "string" and info[name] and true or false
            end;

            --- Set the structure's array element type
            -- @static
            -- @method  SetArrayElement
            -- @owner   struct
            -- @format  (structure, elementType[, stack])
            -- @param   structure       the structure
            -- @param   elementType     the element's type
            -- @param   stack           the stack level
            ["SetArrayElement"] = function(target, eleType, stack)
                local info, def = getStructTargetInfo(target)
                stack = (type(stack) == "number" and stack or 1) + 1

                if info then
                    if not def then error(strformat("Usage: struct.SetArrayElement(structure, eleType[, stack]) - The %s's definition is finished", tostring(target)), stack) end
                    if info[FLD_STRUCT_MEMBERSTART] then error("Usage: struct.SetArrayElement(structure, eleType[, stack]) - The structure has member settings, can't set array element", stack) end

                    local tpValid = getTypeValueValidate(eleType)
                    if not tpValid then error("Usage: struct.SetArrayElement(structure, eleType[, stack]) - The element type is not valid", stack) end

                    info[FLD_STRUCT_ARRAY]      = eleType
                    info[FLD_STRUCT_ARRVALID]   = tpValid
                else
                    error("Usage: struct.SetArrayElement(structure, eleType[, stack]) - The structure is not valid", stack)
                end
            end;

            --- Set the structure's base structure
            -- @static
            -- @method  SetBaseStruct
            -- @owner   struct
            -- @format  (structure, base[, stack])
            -- @param   structure       the structure
            -- @param   base            the base structure
            -- @param   stack           the stack level
            ["SetBaseStruct"]   = function(target, base, stack)
                local info, def = getStructTargetInfo(target)
                stack = (type(stack) == "number" and stack or 1) + 1

                if info then
                    if not def then error(strformat("Usage: struct.SetBaseStruct(structure, base) - The %s's definition is finished", tostring(target)), stack) end
                    if not struct.Validate(base) then error("Usage: struct.SetBaseStruct(structure, base) - The base must be a structure", stack) end
                    info[FLD_STRUCT_BASE] = base
                    attribute.InheritAttributes(target, ATTRTAR_STRUCT, base)
                else
                    error("Usage: struct.SetBaseStruct(structure, base[, stack]) - The structure is not valid", stack)
                end
            end;

            --- Set the structure's default value, only for custom struct type
            -- @static
            -- @method  SetDefault
            -- @owner   struct
            -- @format  (structure, default[, stack])
            -- @param   structure       the structure
            -- @param   default         the default value
            -- @param   stack           the stack level
            ["SetDefault"]      = function(target, default, stack)
                local info, def = getStructTargetInfo(target)
                stack = (type(stack) == "number" and stack or 1) + 1

                if info then
                    if not def then error(strformat("Usage: struct.SetDefault(structure, default[, stack]) - The %s's definition is finished", tostring(target)), stack) end
                    info[FLD_STRUCT_DEFAULT] = default
                else
                    error("Usage: struct.SetDefault(structure, default[, stack]) - The structure is not valid", stack)
                end
            end;

            --- Set the structure's validator
            -- @static
            -- @method  SetValidator
            -- @owner   struct
            -- @format  (structure, func[, stack])
            -- @param   structure       the structure
            -- @param   func            the validator
            -- @param   stack           the stack level
            ["SetValidator"]    = function(target, func, stack)
                local info, def = getStructTargetInfo(target)
                stack = (type(stack) == "number" and stack or 1) + 1

                if info then
                    if not def then error(strformat("Usage: struct.SetValidator(structure, validator[, stack]) - The %s's definition is finished", tostring(target)), stack) end
                    if type(func) ~= "function" then error("Usage: struct.SetValidator(structure, validator) - The validator must be a function", stack) end
                    info[FLD_STRUCT_VALIDSTART] = func
                else
                    error("Usage: struct.SetValidator(structure, validator[, stack]) - The structure is not valid", stack)
                end
            end;

            --- Set the structure's initializer
            -- @static
            -- @method  SetInitializer
            -- @owner   struct
            -- @format  (structure, func[, stack])
            -- @param   structure       the structure
            -- @param   func            the initializer
            -- @param   stack           the stack level
            ["SetInitializer"]  = function(target, func, stack)
                local info, def = getStructTargetInfo(target)
                stack = (type(stack) == "number" and stack or 1) + 1

                if info then
                    if not def then error(strformat("Usage: struct.SetInitializer(structure, initializer[, stack]) - The %s's definition is finished", tostring(target)), stack) end
                    if type(func) ~= "function" then error("Usage: struct.SetInitializer(structure, initializer) - The initializer must be a function", stack) end
                    info[FLD_STRUCT_INITSTART] = func
                else
                    error("Usage: struct.SetInitializer(structure, initializer[, stack]) - The structure is not valid", stack)
                end
            end;

            --- Seal the structure
            -- @static
            -- @method  SetSealed
            -- @owner   struct
            -- @format  (structure[, stack])
            -- @param   structure       the structure
            -- @param   stack           the stack level
            ["SetSealed"]       = function(target, stack)
                local info      = getStructTargetInfo(target)
                stack = (type(stack) == "number" and stack or 1) + 1

                if info then
                    if not validateFlags(MOD_SEALED_STRUCT, info[FLD_STRUCT_MOD]) then
                        info[FLD_STRUCT_MOD] = turnOnFlags(MOD_SEALED_STRUCT, info[FLD_STRUCT_MOD])
                    end
                else
                    error("Usage: struct.SetSealed(structure[, stack]) - The structure is not valid", stack)
                end
            end;

            --- Mark a structure's method as static
            -- @static
            -- @method  SetStaticMethod
            -- @owner   struct
            -- @format  (structure, name[, stack])
            -- @param   structure       the structure
            -- @param   name            the method's name
            -- @param   stack           the stack level
            ["SetStaticMethod"] = function(target, name, stack)
                local info, def = getStructTargetInfo(target)
                stack = (type(stack) == "number" and stack or 1) + 1

                if info then
                    if type(name) ~= "string" then error("Usage: struct.SetStaticMethod(structure, name) - the name must be a string", stack) end
                    name = strtrim(name)
                    if name == "" then error("Usage: Usage: struct.SetStaticMethod(structure, name) - The name can't be empty", stack) end
                    if not def then error(strformat("Usage: struct.SetStaticMethod(structure, name) - The %s's definition is finished", tostring(target)), stack) end
                    if not (info[FLD_STRUCT_TYPEMETHOD] and info[FLD_STRUCT_TYPEMETHOD][name] ~= nil) then error(strformat("Usage: struct.SetStaticMethod(structure, name) - The %s has no method named %q", tostring(target), name), stack) end

                    if info[name] == nil then
                        info[name] = info[FLD_STRUCT_TYPEMETHOD][name]
                        info[FLD_STRUCT_TYPEMETHOD][name] = false
                    end
                else
                    error("Usage: struct.SetStaticMethod(structure, name[, stack]) - The structure is not valid", stack)
                end
            end;

            --- Validate the value with a structure
            -- @static
            -- @method  ValidateValue
            -- @owner   struct
            -- @format  (structure, value[, onlyValid[, stack]])
            -- @param   structure       the structure
            -- @param   value           the value used to validate
            -- @param   onlyValid       Only validate the value, no value modifiy(The initializer and object methods won't be applied)
            -- @param   stack           the stack level
            -- @rfomat  (value[, message])
            -- @return  value           the validated value
            -- @return  message         the error message if the validation is failed
            ["ValidateValue"]   = function(target, value, onlyValid, cache)
                local info  = _StructInfo[target]
                if info then
                    if not cache and info[FLD_STRUCT_VALIDCACHE] then
                        cache = _Cache()
                        local ret, msg = info[FLD_STRUCT_VALID](info, value, onlyValid, cache)
                        for k, v in pairs, cache do cache[k] = nil _Cache(v) end _Cache(cache)
                        return ret, msg
                    else
                        return info[FLD_STRUCT_VALID](info, value, onlyValid, cache)
                    end
                else
                    error("Usage: struct.ValidateValue(structure, value[, onlyValid]) - The structure is not valid", 2)
                end
            end;

            -- Whether the value is a struct type
            -- @static
            -- @method  Validate
            -- @owner   struct
            -- @param   value           the value used to validate
            -- @return  value           return the value if it's a struct type, otherwise nil will be return
            ["Validate"]        = function(target)
                return getmetatable(target) == struct and target or nil
            end;
        },
        __newindex              = readOnly,
        __call                  = function(self, ...)
            local visitor, env, target, definition, keepenv, stack  = GetTypeParams(struct, tstruct, ...)
            if not target then error("Usage: struct([env, ][name, ][definition, ][keepenv, ][stack]) - the struct type can't be created", stack) end

            stack           = stack + 1

            struct.BeginDefinition(target, stack)

            local builder   = prototype.NewObject(structbuilder)
            environment.Initialize  (builder)
            environment.SetNameSpace(builder, target)
            environment.SetParent   (builder, env)

            _StructBuilderInDefine  = saveStorage(_StructBuilderInDefine, builder, true)

            if definition then
                builder(definition, stack)
                return target
            else
                if not keepenv then safesetfenv(stack, builder) end
                return builder
            end
        end,
    }

    tstruct                     = prototype (tnamespace, {
        __index                 = function(self, name)
            if type(name) == "string" then
                local info  = _StructInfo[self]
                return info and (info[name] or info[FLD_STRUCT_TYPEMETHOD] and info[FLD_STRUCT_TYPEMETHOD][name]) or namespace.GetNameSpace(self, name)
            end
        end,
        __call                  = function(self, ...)
            local info  = _StructInfo[self]
            local ret   = info[FLD_STRUCT_CTOR](info, ...)
            return ret
        end,
        __metatable             = struct,
    })

    structbuilder               = prototype {
        __tostring              = function(self)
            local owner         = environment.GetNameSpace(self)
            return"[structbuilder]" .. (owner and tostring(owner) or "anonymous")
        end,
        __index                 = function(self, key)
            local value         = environment.GetValue(self, key, _StructBuilderInDefine[self], 2)
            return value
        end,
        __newindex              = function(self, key, value)
            if not setStructBuilderValue(self, key, value, 2) then
                return rawset(self, key, value)
            end
        end,
        __call                  = function(self, definition, stack)
            stack = (type(stack) == "number" and stack or 1) + 1
            if not definition then error("Usage: struct([env, ][name, ][stack]) (definition) - the definition is missing", stack) end

            local owner = environment.GetNameSpace(self)
            if not (owner and _StructBuilderInDefine[self] and _StructBuilderInfo[owner]) then error("The struct's definition is finished", stack) end

            definition = ParseDefinition(attribute.InitDefinition(owner, ATTRTAR_STRUCT, definition), self, stack)

            if type(definition) == "function" then
                setfenv(definition, self)
                definition(self)
            else
                -- Check base struct first
                if definition[STRUCT_KEYWORD_BASE] ~= nil then
                    setStructBuilderValue(self, STRUCT_KEYWORD_BASE, definition[STRUCT_KEYWORD_BASE], stack, true)
                    definition[STRUCT_KEYWORD_BASE] = nil
                end

                -- Index key
                for i, v in ipairs, definition, 0 do
                    setStructBuilderValue(self, i, v, stack, true)
                end

                for k, v in pairs, definition do
                    if type(k) == "string" then
                        setStructBuilderValue(self, k, v, stack, true)
                    end
                end
            end

            _StructBuilderInDefine = saveStorage(_StructBuilderInDefine, self, nil)
            struct.EndDefinition(owner, stack)

            local newMethod     = rawget(self, STRUCT_BUILDER_NEWMTD)
            if newMethod then
                for k in pairs, newMethod do
                    rawset(self, k, struct.GetMethod(owner, k))
                end
                rawset(self, STRUCT_BUILDER_NEWMTD, nil)
            end

            if getfenv(stack) == self then
                safesetfenv(stack, environment.GetParent(self) or _G)
            end

            return owner
        end,
    }

    -----------------------------------------------------------------------
    --                             keywords                              --
    -----------------------------------------------------------------------

    -----------------------------------------------------------------------
    -- Declare a new member for the structure
    --
    -- @keyword     member
    -- @usage       member "Name" { Type = String, Default = "Anonymous", Require = false }
    -----------------------------------------------------------------------
    member                      = prototype {
        __tostring              = function(self) local info = _MemberInfo[self] return info and info[FLD_MEMBER_NAME] end,
        __index                 = {
            ["GetType"]         = function(self) local info = _MemberInfo[self] return info and info[FLD_MEMBER_TYPE] end;
            ["IsRequire"]       = function(self) local info = _MemberInfo[self] return info and info[FLD_MEMBER_REQUIRE] or false end;
            ["GetName"]         = function(self) local info = _MemberInfo[self] return info and info[FLD_MEMBER_NAME] end;
            ["GetDefault"]      = function(self) local info = _MemberInfo[self] return info and info[FLD_MEMBER_DEFAULT] end;
        },
        __newindex              = readOnly,
        __call                  = function(self, ...)
            if self == member then
                local visitor, env, name, definition, flag, stack  = GetFeatureParams(member, ...)
                local owner = visitor and environment.GetNameSpace(visitor)

                if owner and name then
                    if type(definition) == "table" then
                        _MemberAccessOwner  = nil
                        _MemberAccessName   = nil
                        struct.AddMember(owner, name, definition, stack + 1)
                        return
                    else
                        _MemberAccessOwner = owner
                        _MemberAccessName  = name
                        return self
                    end
                elseif type(definition) == "table" then
                    name    = _MemberAccessName
                    owner   = owner or _MemberAccessOwner

                    _MemberAccessOwner  = nil
                    _MemberAccessName   = nil

                    if owner then
                        if name then
                            struct.AddMember(owner, name, definition, stack + 1)
                        else
                            struct.AddMember(owner, definition, stack + 1)
                        end
                        return
                    end
                end

                error([[Usage: member "name" {...}]], stack + 1)
            end
        end,
    }

    -----------------------------------------------------------------------
    -- End the definition of the structure
    --
    -- @keyword     member
    -- @usage       struct "Number"
    --                  function Number(val)
    --                      return type(val) ~= "number" and "%s must be number"
    --                  end
    --              endstruct "Number"
    -----------------------------------------------------------------------
    endstruct                   = PLOOP_PLATFORM_SETTINGS.TYPE_DEFINITION_WITH_OLD_STYLE and function (...)
        local visitor, env, name, definition, flag, stack  = GetFeatureParams(endstruct, ...)
        local owner = visitor and environment.GetNameSpace(visitor)

        stack = stack + 1

        if not owner or not visitor then error([[Usage: endstruct "name" - can't be used here.]], stack) end
        if namespace.GetNameSpaceName(owner, true) ~= name then error(strformat("%s's definition isn't finished", tostring(owner)), stack) end

        _StructBuilderInDefine = saveStorage(_StructBuilderInDefine, visitor, nil)
        struct.EndDefinition(owner, stack)

        local newMethod     = rawget(visitor, STRUCT_BUILDER_NEWMTD)
        if newMethod then
            for k in pairs, newMethod do
                rawset(visitor, k, struct.GetMethod(owner, k))
            end
            rawset(visitor, STRUCT_BUILDER_NEWMTD, nil)
        end

        local baseEnv       = environment.GetParent(visitor) or _G

        setfenv(stack, baseEnv)

        return baseEnv
    end or nil
end

-------------------------------------------------------------------------------
--                             interface & class                             --
-------------------------------------------------------------------------------
do
    -----------------------------------------------------------------------
    --                         attribute targets                         --
    -----------------------------------------------------------------------
    ATTRTAR_INTERFACE           = attribute.RegisterTargetType("Interface")
    ATTRTAR_CLASS               = attribute.RegisterTargetType("Class")
    ATTRTAR_CLASS_METHOD        = attribute.RegisterTargetType("ClassMethod")
    ATTRTAR_INTERFACE_METHOD    = attribute.RegisterTargetType("InterfaceMethod")
    ATTRTAR_META_METHOD         = attribute.RegisterTargetType("Metamethod")
    ATTRTAR_CLASS_CONSTRUCTOR   = attribute.RegisterTargetType("Constructor")

    -----------------------------------------------------------------------
    --                          private storage                          --
    -----------------------------------------------------------------------
    local _ICInfo               = setmetatable({}, WEAK_KEY)        -- INTERFACE & CLASS INFO
    local _BDInfo               = setmetatable({}, WEAK_KEY)        -- TYPE BUILDER INFO
    local _CLDInfo              = {}                                -- CHILDREN MAP
    local _ThisMap              = setmetatable({}, WEAK_ALL)        -- THIS  -> CLASS
    local _SuperMap             = setmetatable({}, WEAK_ALL)        -- SUPER -> CLASS | INTERFACE

    local _IndexMap             = {}
    local _NewIdxMap            = {}
    local _CtorMap              = {}

    local _InDef                = setmetatable({}, WEAK_KEY)

    -- FEATURE MODIFIER
    local MOD_SEAL_IC           = 2^0           -- SEALED TYPE
    local MOD_FINAL_IC          = 2^1           -- FINAL TYPE
    local MOD_ABSCLS_IC         = 2^2           -- ABSTRACT CLASS
    local MOD_ATCACHE_IC        = 2^3           -- AUTO CACHE CLASS
    local MOD_OBJMDAT_IC        = 2^4           -- ENABLE OBJECT METHOD ATTRIBUTE
    local MOD_NRAWSET_IC        = 2^5           -- NO RAW SET FOR OBJECTS
    local MOD_ASSPCLS_IC        = 2^6           -- AS A SIMPLE CLASS
    local MOD_SIMPVER_IC        = 2^7           -- SIMPLE VERSION CLASS - NO VERSION CONTROL
    local MOD_ODSUPER_IC        = 2^8           -- OLD SUPER STYLE
    local MOD_THDSAFE_IC        = 2^9           --  @todo: THREAD SAFE, can't be all controlled by the system

    local MOD_INITVAL_IC        = (function()
        local v
        if PLOOP_PLATFORM_SETTINGS.CLASS_ALL_SIMPLE_VERSION then
            v = turnOnFlags(0, MOD_SIMPVER_IC)
        end
        if PLOOP_PLATFORM_SETTINGS.CLASS_ALL_OLD_SUPER_STYLE then
            return turnOnFlags(v or 0, MOD_ODSUPER_IC)
        end
    end)()

    -- FIELDS
    local FLD_IC_MOD            = -1            -- FIELD MODIFIER
    local FLD_IC_SUPCLS         =  0            -- FIELD SUPER CLASS
    local FLD_IC_STEXT          =  1            -- FIELD EXTEND INTERFACE START INDEX(keep 1 so we can use unpack on it)
    local FLD_IC_INIT           = -2            -- FIELD INITIALIZER
    local FLD_IC_DISPOSE        = -3            -- FIELD DISPOSE
    local FLD_IC_TYPFTR         = -4            -- FILED TYPE FEATURES
    local FLD_IC_TYPMTD         = -5            -- FIELD TYPE METHODS
    local FLD_IC_TYPMTM         = -6            -- FIELD TYPE META-METHODS
    local FLD_IC_INHRTP         = -7            -- FIELD INHERITANCE PRIORITY
    local FLD_IC_STAFTR         = -8            -- FIELD STATIC TYPE FEATURES
    local FLD_IC_OBJFTR         = -9            -- FIELD OBJECT FEATURES
    local FLD_IC_OBJMTD         =-10            -- FIELD OBJECT METHODS
    local FLD_IC_OBJMTM         =-11            -- FIELD OBJECT META-METHODS
    local FLD_IC_REQCLS         =-12            -- FIELD REQUIR CLASS FOR INTERFACE
    local FLD_IC_ONEVRM         =-13            -- FIELD WHETHER ONE VIRTUAL-METHOD INTERFACE
    local FLD_IC_ANYMSCL        =-14            -- FIELD ANONYMOUS CLASS FOR INTERFACE
    local FLD_IC_SIMPCLS        =-15            -- FIELD CLASS IS A SIMPLE CLASS
    local FLD_IC_SUPINFO        =-16            -- FIELD INFO CACHE FOR SUPER CLASS & EXTEND INTERFACES
    local FLD_IC_SUPCACH        =-17            -- FIELD SUPER CACHE
    local FLD_IC_NEWFTR         =-18            -- FIELD TYPE NEW FEATURES

    -- Ctor & Dispose
    local FLD_IC_CTOR           = 10^4          -- FIELD THE CONSTRUCTOR
    local FLD_IC_CLINIT         = FLD_IC_CTOR + 1   -- FEILD THE CLASS INITIALIZER
    local FLD_IC_ENDISP         = FLD_IC_CTOR - 1   -- FIELD ALL EXTEND INTERFACE DISPOSE END INDEX
    local FLD_IC_STINIT         = FLD_IC_CLINIT + 1 -- FIELD ALL EXTEND INTERFACE INITIALIZER START INDEX

    -- Inheritance priority
    local INRT_PRIORITY_FINAL   =  1
    local INRT_PRIORITY_NORMAL  =  0
    local INRT_PRIORITY_VIRTUAL = -1

    -- Flags for object accessing
    local FLG_IC_OBJMTD         = 2^0           -- HAS OBJECT METHOD
    local FLG_IC_OBJFTR         = 2^1           -- HAS OBJECT FEATURE
    local FLG_IC_ATCACH         = 2^2           -- IS  AUTO CACHE
    local FLG_IC_IDXFUN         = 2^3           -- HAS INDEX FUNCTION
    local FLG_IC_IDXTBL         = 2^4           -- HAS INDEX TABLE
    local FLG_IC_NEWIDX         = 2^5           -- HAS NEW INDEX
    local FLG_IC_OBJATR         = 2^6           -- ENABLE OBJECT METHOD ATTRIBUTE
    local FLG_IC_NRAWST         = 2^7           -- ENABLE NO RAW SET
    local FLG_IC_SUPACC         = 2^8           -- HAS SUPER METHOD OR FEATURE
    local FLG_IC_TDSAFE         = 2^9           -- THREAD SAFE

    -- Flags for constructor
    local FLG_IC_EXTOBJ         = 2^2           -- HAS __exist
    local FLG_IC_NEWOBJ         = 2^3           -- HAS __new
    local FLG_IC_SIMCLS         = 2^4           -- SIMPLE CLASS
    local FLG_IC_ASSIMP         = 2^5           -- AS SIMPLE CLASS
    local FLG_IC_HSCLIN         = 2^6           -- HAS CLASS INITIALIZER
    local FLG_IC_HASIFS         = 2^7           -- NEED CALL INTERFACE'S INITIALIZER

    -- Meta-Methods
    local IC_KEYWORD_EXIST      = "__exist"
    local IC_KEYWORD_NEW        = "__new"
    local IC_KEYWORD_INDEX      = "__index"
    local IC_KEYWORD_NEWIDX     = "__newindex"
    local IC_KEYWORD_META       = "__metatable"

    -- Dispose Method
    local IC_KEYWORD_DISPOB     = "Dispose"

    -- Super & This
    local AL_SUPER              = "Super"
    local AL_THIS               = "This"
    local SP_ACCESS             = "__PLOOP_SUPER_ACCESS"

    -- Type Builder
    local IC_BUILDER_NEWMTD              = "__PLOOP_BD_NEWMTD"

    local META_KEYS             = {
        __add                   = "__add",      -- a + b
        __sub                   = "__sub",      -- a - b
        __mul                   = "__mul",      -- a * b
        __div                   = "__div",      -- a / b
        __mod                   = "__mod",      -- a % b
        __pow                   = "__pow",      -- a ^ b
        __unm                   = "__unm",      -- - a
        __idiv                  = "__idiv",     -- // floor division
        __band                  = "__band",     -- & bitwise and
        __bor                   = "__bor",      -- | bitwise or
        __bxor                  = "__bxor",     -- ~ bitwise exclusive or
        __bnot                  = "__bnot",     -- ~ bitwise unary not
        __shl                   = "__shl",      -- << bitwise left shift
        __shr                   = "__shr",      -- >> bitwise right shift
        __concat                = "__concat",   -- a..b
        __len                   = "__len",      -- #a
        __eq                    = "__eq",       -- a == b
        __lt                    = "__lt",       -- a < b
        __le                    = "__le",       -- a <= b
        __index                 = "___index",   -- return a[b]
        __newindex              = "___newindex",-- a[b] = v
        __call                  = "__call",     -- a()
        __gc                    = "__gc",       -- dispose a
        __tostring              = "__tostring", -- tostring(a)
        __ipairs                = "__ipairs",   -- ipairs(a)
        __pairs                 = "__pairs",    -- pairs(a)

        -- Ploop only meta-methods
        __exist                 = "__exist",    -- return object if existed
        __new                   = "__new",      -- return a raw table as the object
    }

    -- Helpers
    local function getICTargetInfo(target)
        local info  = _BDInfo[target]
        if info then return info, true else return _ICInfo[target], false end
    end

    local function getSuperInfo(info, target)
        return info[FLD_IC_SUPINFO] and info[FLD_IC_SUPINFO][target] or _BDInfo[target] or _ICInfo[target]
    end

    local function getSuperInfoIter(info, reverse)
        if reverse then
            if info[FLD_IC_SUPCLS] then
                local scache    = _Cache()
                local scls      = info[FLD_IC_SUPCLS]
                while scls do
                    tinsert(scache, scls)
                    scls        = getSuperInfo(info, scls)[FLD_IC_SUPCLS]
                end

                local scnt      = #scache - FLD_IC_STEXT + 1
                return function(root, idx)
                    if idx >= FLD_IC_STEXT then
                        local extif = root[idx]
                        return idx - 1, getSuperInfo(info, extif), extif
                    elseif scnt + idx > 0 then
                        local scls  = scache[scnt + idx]
                        return idx - 1, getSuperInfo(info, scls), scls
                    end
                    _Cache(scache)
                end, info, #info
            else
                return function(root, idx)
                    if idx >= FLD_IC_STEXT then
                        local extif = root[idx]
                        return idx - 1, getSuperInfo(info, extif), extif
                    end
                end, info, #info
            end
        else
            return function(root, idx)
                if type(idx) == "table" then
                    local scls  = idx[FLD_IC_SUPCLS]
                    if scls then
                        idx     = getSuperInfo(info, scls)
                        return idx, idx, scls
                    end
                    idx         = FLD_IC_STEXT - 1
                end
                idx             = idx + 1
                local extif     = root[idx]
                if extif then return idx, getSuperInfo(info, extif), extif end
            end, info, info
        end
    end

    local function getSuperOnPriority(info, name, get)
        local minpriority, norpriority
        for _, sinfo in getSuperInfoIter(info) do
            local m = get(sinfo, name)
            if m then
                local priority = sinfo[FLD_IC_INHRTP] and sinfo[FLD_IC_INHRTP][name] or INRT_PRIORITY_NORMAL
                if priority == INRT_PRIORITY_FINAL   then return m, INRT_PRIORITY_FINAL end
                if priority == INRT_PRIORITY_VIRTUAL then
                    minpriority = minpriority or m
                else
                    norpriority = norpriority or m
                end
            end
        end
        if norpriority then
            return norpriority, INRT_PRIORITY_NORMAL
        elseif minpriority then
            return minpriority, INRT_PRIORITY_VIRTUAL
        end
    end

    local function getTypeMethod(info, name)
        return info[FLD_IC_TYPMTD] and info[FLD_IC_TYPMTD][name]
    end

    local function getTypeFeature(info, name)
        return info[FLD_IC_TYPFTR] and info[FLD_IC_TYPFTR][name]
    end

    local function getTypeMetaMethod(info, name)
        return info[FLD_IC_TYPMTM] and info[FLD_IC_TYPMTM][META_KEYS[name]]
    end

    local function getSuperMethod(info, name)
        return getSuperOnPriority(info, name, getTypeMethod)
    end

    local function getSuperFeature(info, name, ftype)
        local feature, priority = getSuperOnPriority(info, name, getTypeFeature)
        return feature and (not ftype and feature or ftype.Validate(feature)) or nil, priority
    end

    local function getSuperMetaMethod(info, name)
        return getSuperOnPriority(info, name, getTypeMetaMethod)
    end

    -- Type Building
    local function generateSuperInfo(info, lst, cache)
        if info then
            local scls      = info[FLD_IC_SUPCLS]
            if scls then
                local sinfo = getICTargetInfo(scls)
                generateSuperInfo(sinfo, lst, cache)
                if cache then cache[scls] = sinfo end
            end

            for i = #info, FLD_IC_STEXT, -1 do
                local extif = info[i]
                if not lst[extif] then
                    lst[extif]  = true

                    local sinfo = getICTargetInfo(extif)
                    generateSuperInfo(sinfo, lst, cache)
                    if cache then cache[extif] = sinfo end
                    tinsert(lst, extif)
                end
            end
        end

        return lst, cache
    end

    local function generateCacheOnPriority(source, target, objpri, inhrtp, super)
        for k, v in pairs, source do
            if v then
                local priority  = inhrtp and inhrtp[k] or INRT_PRIORITY_NORMAL
                if priority >= (objpri[k] or INRT_PRIORITY_VIRTUAL) then
                    if super and target[k] and not super[k] then
                        super[k]= target[k]
                    end

                    objpri[k]   = priority
                    target[k]   = v
                end
            end
        end
    end

    local function generateMetaIndex(info)
        local token = 0
        local upval = _Cache()
        local meta  = info[FLD_IC_OBJMTM]

        if validateFlags(MOD_ATCACHE_IC, info[FLD_IC_MOD]) then
            token   = turnOnFlags(FLG_IC_ATCACH, token)
        end

        if info[FLD_IC_OBJFTR] and next(info[FLD_IC_OBJFTR]) then
            token   = turnOnFlags(FLG_IC_OBJFTR, token)
            tinsert(upval, info[FLD_IC_OBJFTR])
        end

        if info[FLD_IC_OBJMTD] and next(info[FLD_IC_OBJMTD]) then
            token   = turnOnFlags(FLG_IC_OBJMTD, token)
            tinsert(upval, info[FLD_IC_OBJMTD])
        end

        if meta[IC_KEYWORD_INDEX] then
            if type(meta[IC_KEYWORD_INDEX]) == "function" then
                token = turnOnFlags(FLG_IC_IDXFUN, token)
            else
                token = turnOnFlags(FLG_IC_IDXTBL, token)
            end
            tinsert(upval, meta[IC_KEYWORD_INDEX])
        end

        -- No __index generated
        if token == 0                               then meta[IC_KEYWORD_INDEX] = nil      return _Cache(upval) end
        -- Use the object method cache directly
        if token == FLG_IC_OBJMTD                       then meta[IC_KEYWORD_INDEX] = objmtd   return _Cache(upval) end
        -- Use the custom __index directly
        if token == FLG_IC_IDXFUN or token == FLG_IC_IDXTBL then                            return _Cache(upval) end

        if not _IndexMap[token] then
            local header    = _Cache()
            local body      = _Cache()

            tinsert(body, "")   -- Remain for closure values
            tinsert(body, [[return function(self, key)]])

            if validateFlags(FLG_IC_OBJFTR, token) then
                tinsert(header, "features")
                tinsert(body, [[
                    local ftr = features[key]
                    if ftr then return ftr:Get(self) end
                ]])
            end

            if validateFlags(FLG_IC_OBJMTD, token) then
                tinsert(header, "methods")
                tinsert(body, [[
                    local mtd = methods[key]
                    if mtd then
                ]])
                if validateFlags(FLG_IC_ATCACH, token) then
                    tinsert(body, [[rawset(self, key, mtd)]])
                end
                tinsert(body, [[
                        return mtd
                    end
                ]])
            end


            if validateFlags(FLG_IC_IDXFUN, token) then
                tinsert(header, "_index")
                tinsert(body, [[return _index(self, key)]])
            elseif validateFlags(FLG_IC_IDXTBL, token) then
                tinsert(header, "_index")
                tinsert(body, [[return _index[key] ]])
            end

            tinsert(body, [[end]])

            if #header > 0 then
                body[1] = "local " .. tblconcat(header, ",") .. "= ..."
            end

            _IndexMap[token] = loadSnippet(tblconcat(body, "\n"), "Class_Index_" .. token)

            _Cache(header)
            _Cache(body)
        end

        meta[IC_KEYWORD_INDEX] = _IndexMap[token](unpack(upval))
        _Cache(upval)
    end

    local function generateMetaNewIndex(info)
        local token = 0
        local upval = _Cache()
        local meta  = info[FLD_IC_OBJMTM]

        if validateFlags(MOD_OBJMDAT_IC, info[FLD_IC_MOD]) then
            token   = turnOnFlags(FLG_IC_OBJATR, token)
        end

        if validateFlags(MOD_NRAWSET_IC, info[FLD_IC_MOD]) then
            token   = turnOnFlags(FLG_IC_NRAWST, token)
        end

        if info[FLD_IC_OBJFTR] and next(info[FLD_IC_OBJFTR]) then
            token   = turnOnFlags(FLG_IC_OBJFTR, token)
            tinsert(upval, info[FLD_IC_OBJFTR])
        end

        if meta[IC_KEYWORD_NEWIDX] then
            token   = turnOnFlags(FLG_IC_NEWIDX, token)
            tinsert(upval, meta[IC_KEYWORD_NEWIDX])
        end

        -- No __newindex generated
        if token == 0         then meta[IC_KEYWORD_NEWIDX] = nil   return _Cache(upval) end
        -- Use the custom __newindex directly
        if token == FLG_IC_NEWIDX then                          return _Cache(upval) end

        if not _NewIdxMap[token] then
            local header    = _Cache()
            local body      = _Cache()

            tinsert(body, "")   -- Remain for closure values
            tinsert(body, [[return function(self, key, value)]])

            if validateFlags(FLG_IC_OBJFTR, token) then
                tinsert(header, "feature")
                tinsert(body, [[
                    local ftr = feature[key]
                    if ftr then ftr:Set(self, value, 3) return end
                ]])
            end

            if validateFlags(FLG_IC_NEWIDX, token) or not validateFlags(FLG_IC_NRAWST, token) then
                if validateFlags(FLG_IC_OBJATR, token) then
                    tinsert(body, [[
                        if type(value) == "function" then
                            attribute.SaveAttributes(value, ATTRTAR_FUNCTION, 3)
                            value = attribute.ApplyAttributes(value, ATTRTAR_FUNCTION, nil, self, name)
                        end
                    ]])
                end

                if validateFlags(FLG_IC_NEWIDX, token) then
                    tinsert(header, "_newindex")
                    tinsert(body, [[_newindex(self, key, value)]])
                else
                    tinsert(body, [[rawset(self, key, value)]])
                end

                if validateFlags(FLG_IC_OBJATR, token) then
                    tinsert(body, [[)
                        if type(value) == "function" then
                            attribute.AttachAttributes(value, ATTRTAR_FUNCTION, self, name)
                        end
                    ]])
                end
            else
                tinsert(body, [[error("The object is readonly", 2)]])
            end

            tinsert(body, [[end]])

            if #header > 0 then
                body[1] = "local " .. tblconcat(header, ",") .. "= ..."
            end

            _NewIdxMap[token] = loadSnippet(tblconcat(body, "\n"), "Class_NewIndex_" .. token)

            _Cache(header)
            _Cache(body)
        end

        meta[IC_KEYWORD_NEWIDX] = _NewIdxMap[token](unpack(upval))
        _Cache(upval)
    end

    local function loadInitTable(obj, initTable)
        for name, value in pairs, initTable do obj[name] = value end
    end

    local function generateConstructor(target, info)
        local token = 0
        local upval = _Cache()
        local meta  = info[FLD_IC_OBJMTM]

        if validateFlags(MOD_ABSCLS_IC, info[FLD_IC_MOD]) then
            local msg = strformat("The %s is abstract, can't be used to create objects", tostring(target))
            info[FLD_IC_CTOR] = function() error(msg, 3) end
            return _Cache(upval)
        end

        tinsert(upval, info)
        tinsert(upval, meta)
        tinsert(upval, target)

        if meta[IC_KEYWORD_EXIST] then
            token   = turnOnFlags(FLG_IC_EXTOBJ, token)
            tinsert(upval, meta[IC_KEYWORD_EXIST])
        end

        if meta[IC_KEYWORD_NEW] then
            token   = turnOnFlags(FLG_IC_NEWOBJ, token)
            tinsert(upval, meta[IC_KEYWORD_NEW])
        end

        if info[FLD_IC_SIMPCLS] then
            token   = turnOnFlags(FLG_IC_SIMCLS, token)
        elseif validateFlags(MOD_ASSPCLS_IC, info[FLD_IC_MOD]) then
            token   = turnOnFlags(FLG_IC_ASSIMP, token)

            if info[FLD_IC_OBJFTR] and next(info[FLD_IC_OBJFTR]) then
                token   = turnOnFlags(FLG_IC_OBJFTR, token)
                tinsert(upval, info[FLD_IC_OBJFTR])
            end
        end

        if info[FLD_IC_CLINIT] then
            token   = turnOnFlags(FLG_IC_HSCLIN, token)
            tinsert(upval, info[FLD_IC_CLINIT])
        else
            tinsert(upval, loadInitTable)
        end

        if info[FLD_IC_STINIT] then
            token   = turnOnFlags(FLG_IC_HASIFS, token)
            local i = FLD_IC_STINIT
            while info[i + 1] do i = i + 1 end
            tinsert(upval, i)
        end

        if not _CtorMap[token] then
            local header    = _Cache()
            local body      = _Cache()

            tinsert(header, "_info")
            tinsert(header, "_meta")
            tinsert(header, "_class")

            tinsert(body, "")   -- Remain for closure values
            tinsert(body, [[return function(...)]])

            tinsert(body, [[local obj]])

            if validateFlags(FLG_IC_EXTOBJ, token) then
                tinsert(header, "_exist")

                tinsert(body, [[
                    obj = _exist(...)
                    if obj then
                        local cls = getmetatable(obj)
                        if cls == _class or class.IsSubType(cls, _class) then
                            return obj
                        end
                    end
                ]])
            end

            if validateFlags(FLG_IC_NEWOBJ, token) then
                tinsert(header, "_new")

                tinsert(body, [[
                    obj = _new(...)
                    if type(obj) == "table" then
                        local ok, ret = pcall(setmetatable, obj, _meta)
                        if not ok then error(strformat("The %s's __new meta-method doesn't provide a valid table as object", tostring(_class)), 3) end
                    else
                        obj = nil
                    end
                ]])
            end

            if validateFlags(FLG_IC_SIMCLS, token) or validateFlags(FLG_IC_ASSIMP, token) or not validateFlags(FLG_IC_HSCLIN, token) then
                tinsert(body, [[
                    local init = nil
                    if select("#", ...) == 1 then
                        init = select(1, ...)
                        if type(init) == "table" and getmetatable(init) == nil then
                            if not obj then
                ]])

                if validateFlags(FLG_IC_SIMCLS, token) then
                    tinsert(body, [[obj = setmetatable(init, _meta) init = false]])
                elseif validateFlags(FLG_IC_ASSIMP, token) then
                    tinsert(body, [[local noconflict = true]])

                    if validateFlags(FLG_IC_OBJFTR, token) then
                        tinsert(header, "_ftr")
                        tinsert(body, [[
                            for k in pairs, _ftr do
                                if init[k] ~= nil then
                                    noconflict = false break
                                end
                            end
                        ]])
                    end

                    tinsert(body, [[if noconflict then obj = setmetatable(init, _meta) init = false end]])
                end

                tinsert(body, [[
                            end
                        else
                            init = nil
                        end
                    end
                ]])
            end

            tinsert(body, [[obj = obj or setmetatable({}, _meta)]])

            if validateFlags(FLG_IC_HSCLIN, token) then
                tinsert(header, "_ctor")

                if validateFlags(FLG_IC_SIMCLS, token) or validateFlags(FLG_IC_ASSIMP, token) then
                    tinsert(body, [[
                        if init == false then
                            _ctor(obj)
                        else
                            _ctor(obj, ...)
                        end
                    ]])
                else
                    tinsert(body, [[_ctor(obj, ...)]])
                end
            else
                tinsert(header, "_loadInitTable")

                tinsert(body, [[
                    if init then
                        local ok, msg = pcall(_loadInitTable, obj, init)
                        if not ok then error(strmatch(msg, "%d+:%s*(.-)$") or msg, 3) end
                    end
                ]])
            end

            if validateFlags(FLG_IC_HASIFS, token) then
                tinsert(header, "_max")

                tinsert(body, [[
                    for i = ]] .. FLD_IC_STINIT .. [[, _max do
                        _info[i](obj)
                    end
                ]])
            end

            tinsert(body, [[
                    return obj
                end
            ]])

            if #header > 0 then
                body[1] = "local " .. tblconcat(header, ",") .. "= ..."
            end

            _CtorMap[token] = loadSnippet(tblconcat(body, "\n"), "Class_Ctor_" .. token)

            _Cache(header)
            _Cache(body)
        end

        info[FLD_IC_CTOR] = _CtorMap[token](unpack(upval))
        _Cache(upval)
    end

    local function generateTypeCaches(target, info)
        local objpri    = _Cache()
        local objmeta   = _Cache()
        local objftr    = _Cache()
        local objmtd    = _Cache()
        local super     = _Cache()

        for _, sinfo in getSuperInfoIter(info, true) do
            local inhrtp= sinfo[FLD_IC_INHRTP]

            if sinfo[FLD_IC_TYPMTM] then
                generateCacheOnPriority(sinfo[FLD_IC_TYPMTM], objmeta, objpri, inhrtp)
            end

            if sinfo[FLD_IC_TYPFTR] then
                generateCacheOnPriority(sinfo[FLD_IC_TYPFTR], objftr, objpri, inhrtp)
            end

            if sinfo[FLD_IC_TYPMTD] then
                generateCacheOnPriority(sinfo[FLD_IC_TYPMTD], objmtd, objpri, inhrtp)
            end
        end

        local inhrtp    = info[FLD_IC_INHRTP]
        if info[FLD_IC_TYPMTM] then
            generateCacheOnPriority(info[FLD_IC_TYPMTM], objmeta, objpri, inhrtp, super)
        end

        if info[FLD_IC_TYPFTR] then
            generateCacheOnPriority(info[FLD_IC_TYPFTR], objftr, objpri, inhrtp, super)
        end

        if info[FLD_IC_TYPMTD] then
           generateCacheOnPriority(info[FLD_IC_TYPMTD], objmtd, objpri, inhrtp, super)
        end

        if interface.Validate(target) then
            -- Check one virtual method
            local onevtm
            for k, v in pairs, objmtd do
                if objpri[k] == INRT_PRIORITY_VIRTUAL then
                    if not onevtm then
                        onevtm  = k
                    else
                        onevtm  = false
                        break
                    end
                end
            end
            info[FLD_IC_ONEVRM] = onevtm or nil
        else
            if not validateFlags(MOD_ABSCLS_IC, info[FLD_IC_MOD]) then
                objmeta[IC_KEYWORD_META]   = target

                info[FLD_IC_OBJMTM]     = objmeta
                info[FLD_IC_OBJFTR]     = objftr
                info[FLD_IC_OBJMTD]     = objmtd

                generateMetaIndex(info)
                generateMetaNewIndex(info)
            end
            generateConstructor(target, info)
        end

        if next(super) then
            info[FLD_IC_SUPCACH]    = super
        else
            _Cache(super)
        end
    end

    local function endDefinitionForNewFeatures(target, stack)
        local info = getICTargetInfo(target)

        if info[FLD_IC_NEWFTR] then
            info[FLD_IC_TYPFTR] = info[FLD_IC_TYPFTR] or _Cache()

            for name, ftr in pairs, info[FLD_IC_NEWFTR] do
                getmetatable(ftr).EndDefinition(ftr, target, name, stack + 1)
            end

            _Cache(info[FLD_IC_NEWFTR])
            info[FLD_IC_NEWFTR] = nil
        end
    end

    -- Shared APIS
    local function checkInfoWithName(tType, target, name, allowDefined)
        local info, def = getICTargetInfo(target)
        if not info then return nil, nil, strformat("The %s is not valid", tostring(tType)) end
        if not allowDefined and not def then return nil, nil, strformat("The %s's definition is finished", tostring(target)) end
        if not name or type(name) ~= "string" then return info, nil, "The name must be a string." end
        name = strtrim(name)
        if name == "" then return info, nil, "The name can't be empty." end
        return info, name, nil, def
    end

    local function reDefineChildren(target, stack)
        if _CLDInfo[target] then
            for _, child in ipairs, _CLDInfo[target], 0 do
                if not _BDInfo[child] then  -- Not in definition mode
                    if interface.Validate(child) then
                        interface.RefreshDefinition(child, stack + 1)
                    else
                        class.RefreshDefinition(child, stack + 1)
                    end
                end
            end
        end
    end

    local function beginDefinition(target, stack)
        if not _BDInfo[0] then
            Lock(interface)
            _BDInfo[0] = target
            return true
        end
        return false
    end

    local function endDefinition(target, stack, noChildUpdate)
        -- Update children
        if not noChildUpdate then reDefineChildren(target, stack + 1) end

        if _BDInfo[0] == target then
            _BDInfo[0] = nil
            Release(interface)
        end
    end

    local function addSuperType(info, target, supType)
        local isIF          = interface.Validate(supType)

        -- Clear _CLDInfo for old extend interfaces
        for i = #info, FLD_IC_STEXT, -1 do
            local extif     = info[i]

            if interface.IsSubType(supType, extif) then
                for k, v in ipairs, _CLDInfo[extif], 0 do
                    if v == target then tremove(_CLDInfo[extif], k) break end
                end
            end

            if isIF then info[i + 1] = extif end
        end

        if isIF then
            info[FLD_IC_STEXT]  = supType
        else
            info[FLD_IC_SUPCLS] = supType
        end

        -- Register the _CLDInfo
        _CLDInfo[supType]   = _CLDInfo[supType] or {}
        tinsert(_CLDInfo[supType], target)

        -- Re-generate the interface order list
        local lstIF         = generateSuperInfo(info, _Cache())
        local idxIF         = FLD_IC_STEXT + #lstIF

        for i, extif in ipairs, lstIF, 0 do
            info[idxIF - i] = extif
        end
        _Cache(lstIF)
    end

    local function addExtend(tType, target, extendIF, stack)
        local info, _, msg  = checkInfoWithName(tType, target)
        stack = (type(stack) == "number" and stack or 2) + 1

        if not info then error(strformat("Usage: %s.AddExtend(%s, extendinterface[, stack]) - ", tostring(tType), tostring(tType)) .. msg, stack) end

        if not interface.Validate(extendIF) then error(strformat("Usage: %s.AddExtend(%s, extendinterface[, stack]) - the extendinterface must be an interface", tostring(tType), tostring(tType)), stack) end
        if interface.IsFinal(extendIF) then error(strformat("Usage: %s.AddExtend(%s, extendinterface[, stack]) - The %s is marked as final, can't be extended", tostring(tType), tostring(tType), tostring(extendIF)), stack) end

        -- Check if already extended
        if interface.IsSubType(target, extendIF) then return end

        -- Check the extend interface's require class
        local reqcls = interface.GetRequireClass(extendIF)

        if class.Validate(target) then
            if reqcls and not class.IsSubType(target, reqcls) then
                error(strformat("Usage: class.AddExtend(class, extendinterface[, stack]) - The class must be %s's sub-class", tostring(reqcls)), stack)
            end
        elseif interface.IsSubType(extendIF, target) then
            error("Usage: interface.AddExtend(interface, extendinterface[, stack]) - The extendinterface is a sub type of the interface", stack)
        elseif reqcls then
            local rcls = interface.GetRequireClass(target)

            if rcls then
                if class.IsSubType(reqcls, rcls) then
                    interface.SetRequireClass(target, reqcls, stack + 1)
                elseif not class.IsSubType(rcls, reqcls) then
                    error(strformat("Usage: interface.AddExtend(interface, extendinterface[, stack]) - The interface's require class must be %s's sub-class", tostring(reqcls)), stack)
                end
            else
                interface.SetRequireClass(target, reqcls, stack + 1)
            end
        end

        -- Add the extend interface
        addSuperType(info, target, extendIF)
    end

    local function addFeature(tType, target, ftype, name, definition, stack)
        local info, name, msg  = checkInfoWithName(tType, target, name)
        stack = (type(stack) == "number" and stack or 2) + 1

        if msg then error(strformat("Usage: %s.AddFeature(%s, featureType, name[, definition][, stack]) - ", tostring(tType), tostring(tType)) .. msg, stack) end

        if not prototype.Validate(ftype) then error(strformat("Usage: %s.AddFeature(%s, featureType, name[, definition][, stack]) - the featureType is not valid", tostring(tType), tostring(tType)), stack) end
        if META_KEYS[name] or name == IC_KEYWORD_DISPOB then error(strformat("Usage: Usage: %s.AddFeature(%s, featureType, name[, definition][, stack]) - The %s can't be used as feature name", tostring(tType), tostring(tType), name), stack) end

        local f = ftype.BeginDefinition(target, name, definition, getSuperFeature(info, name, ftype), stack + 1)

        if f then
            if info[FLD_IC_TYPFTR] and info[FLD_IC_TYPFTR][name] ~= nil then
                if getmetatable(info[FLD_IC_TYPFTR][name] or info[FLD_IC_STAFTR][name]) ~= ftype then
                    error(strformat("Usage: %s.AddFeature(%s, featureType, name[, definition][, stack]) - the %q existed as other feature type", tostring(tType), tostring(tType), name), stack)
                end
                if info[FLD_IC_TYPFTR][name] == false then
                    ftype.SetStatic(f, stack + 1)
                    info[FLD_IC_STAFTR][name] = f
                else
                    info[FLD_IC_TYPFTR][name] = f
                end
            else
                info[FLD_IC_TYPFTR]         = info[FLD_IC_TYPFTR] or _Cache()
                info[FLD_IC_TYPFTR][name]   = f
            end

            info[FLD_IC_NEWFTR]         = info[FLD_IC_NEWFTR] or _Cache()
            info[FLD_IC_NEWFTR][name]   = f
        else
            error(strformat("Usage: Usage: %s.AddFeature(%s, featureType, name[, definition][, stack]) - The feature's creation failed", tostring(tType), tostring(tType)), stack)
        end
    end

    local function addMethod(tType, target, name, func, stack)
        local info, name, msg, def  = checkInfoWithName(tType, target, name, true)
        stack = (type(stack) == "number" and stack or 2) + 1

        if msg then error(strformat("Usage: %s.AddMethod(%s, name, func[, stack]) - ", tostring(tType), tostring(tType)) .. msg, stack) end

        if META_KEYS[name] or name == IC_KEYWORD_DISPOB then error(strformat("Usage: Usage: %s.AddMethod(%s, name, func[, stack]) - The %s can't be used as method name", tostring(tType), tostring(tType), name), stack) end
        if type(func) ~= "function" then error(strformat("Usage: %s.AddMethod(%s, name, func[, stack]) - the func must be a function", tostring(tType), tostring(tType)), stack) end

        -- Consume before type's re-definition
        attribute.SaveAttributes(func, ATTRTAR_METHOD, stack + 1)

        if not def then
            -- This means a simple but required re-definition
            tType.BeginDefinition(target, stack + 1)
            info    = getICTargetInfo(target)
        end

        local nStatic   = not info[name]

        func = attribute.ApplyAttributes(func, ATTRTAR_METHOD, nil, target, name, nStatic and getSuperMethod(info, name) or nil)

        if nStatic then
            info[FLD_IC_TYPMTD] = info[FLD_IC_TYPMTD] or _Cache()
            info[FLD_IC_TYPMTD][name] = func
        else
            info[name]      = func
        end

        attribute.AttachAttributes(func, ATTRTAR_METHOD, target, name)

        if not def then
            tType.EndDefinition(target, stack + 1)
        end
    end

    local function addMetaMethod(tType, target, name, func, stack)
        local info, name, msg  = checkInfoWithName(tType, target, name)
        stack = (type(stack) == "number" and stack or 2) + 1

        if msg then error(strformat("Usage: %s.AddMetaMethod(%s, name, func[, stack]) - ", tostring(tType), tostring(tType)) .. msg, stack) end

        if not META_KEYS[name] then error(strformat("Usage: Usage: %s.AddMetaMethod(%s, name, func[, stack]) - The name isn't a valid meta-method name", tostring(tType), tostring(tType)), stack) end

        local tfunc = type(func)

        if name ~= IC_KEYWORD_INDEX and tfunc ~= "function" then error(strformat("Usage: %s.AddMetaMethod(%s, name, func[, stack]) - the func must be a function", tostring(tType), tostring(tType)), stack) end
        if name == IC_KEYWORD_INDEX and tfunc ~= "function" and tfunc ~= "table" then error(strformat("Usage: %s.AddMetaMethod(%s, name, func[, stack]) - the func must be a function or table for '__index'", tostring(tType), tostring(tType)), stack) end

        if tfunc == "function" then
            attribute.SaveAttributes(func, ATTRTAR_META_METHOD, stack + 1)
            func = attribute.ApplyAttributes(func, ATTRTAR_META_METHOD, nil, target, name)
        end

        info[FLD_IC_TYPMTM]                     = info[FLD_IC_TYPMTM] or _Cache()
        info[FLD_IC_TYPMTM][name]               = func
        if name ~= META_KEYS[name] then
            info[FLD_IC_TYPMTM][META_KEYS[name]]= func
        end

        if tfunc == "table" then
            info[FLD_IC_TYPMTM][META_KEYS[name]]= function(self, key) return func[key] end
        elseif tfunc == "function" then
            attribute.AttachAttributes(func, ATTRTAR_META_METHOD, target, name)
        end
    end

    local function setDispose(tType, target, func, stack)
        local info, _, msg  = checkInfoWithName(tType, target)
        stack = (type(stack) == "number" and stack or 2) + 1

        if not info then error(strformat("Usage: %s.SetDispose(%s, func[, stack]) - ", tostring(tType), tostring(tType)) .. msg, stack) end

        if type(func) ~= "function" then error(strformat("Usage: %s.SetDispose(%s, func[, stack]) - the func must be a function", tostring(tType), tostring(tType)), stack) end

        info[FLD_IC_DISPOSE] = func
    end

    local function setModifiedFlag(tType, target, flag, methodName, stack)
        local info, _, msg  = checkInfoWithName(tType, target)
        stack = (type(stack) == "number" and stack or 2) + 1

        if not info then error(strformat("Usage: %s.%s(%s[, stack]) - ", tostring(tType), methodName, tostring(tType)) .. msg, stack) end

        if not validateFlags(flag, info[FLD_IC_MOD]) then
            info[FLD_IC_MOD] = turnOnFlags(flag, info[FLD_IC_MOD])
        end
    end

    local function setStaticFeature(tType, target, name, stack)
        local info, name, msg   = checkInfoWithName(tType, target, name)
        stack = (type(stack) == "number" and stack or 2) + 1

        if msg then error(strformat("Usage: %s.SetStaticFeature(%s, name[, stack]) - ", tostring(tType), tostring(tType)) .. msg, stack) end

        if not (info[FLD_IC_NEWFTR] and info[FLD_IC_NEWFTR][name]) then
            if info[FLD_IC_OBJFTR] and info[FLD_IC_OBJFTR][name] ~= nil then
                error(strformat("Usage: %s.SetStaticFeature(%s, name[, stack]) - The %s's %q's definition is finished, can't set as static", tostring(tType), tostring(tType), tostring(target), name), stack)
            else
                error(strformat("Usage: %s.SetStaticFeature(%s, name[, stack]) - The %s has no feature named %q", tostring(tType), tostring(tType), tostring(target), name), stack)
            end
        end

        local feature   = info[FLD_IC_NEWFTR][name]
        local ftype     = getmetatable(feature)
        if ftype.SetStatic(feature, stack + 1) then
            info[FLD_IC_STAFTR] = info[FLD_IC_STAFTR] or _Cache()
            info[FLD_IC_STAFTR][name] = feature
            info[FLD_IC_OBJFTR][name] = false
        else
            error(strformat("Usage: %s.SetStaticFeature(%s, name[, stack]) - The %s's feature %q can't be set as static", tostring(tType), tostring(tType), tostring(target), name), stack)
        end
    end

    local function setStaticMethod(tType, target, name, stack)
        local info, name, msg  = checkInfoWithName(tType, target, name)
        stack = (type(stack) == "number" and stack or 2) + 1

        if msg then error(strformat("Usage: %s.SetStaticMethod(%s, name[, stack]) - ", tostring(tType), tostring(tType)) .. msg, stack) end

        if not (info[FLD_IC_TYPMTD] and info[FLD_IC_TYPMTD][name] ~= nil) then error(strformat("Usage: %s.SetStaticMethod(%s, name[, stack]) - The %s has no method named %q", tostring(tType), tostring(tType), tostring(target), name), stack) end

        if info[name] == nil then
            info[name] = info[FLD_IC_TYPMTD][name]
            info[FLD_IC_TYPMTD][name] = false
            if info[FLD_IC_INHRTP] and info[FLD_IC_INHRTP][name] then info[FLD_IC_INHRTP] = nil end
        end
    end

    local function setPriorityFeature(tType, target, name, methodName, priority, stack)
        local info, name, msg  = checkInfoWithName(tType, target, name)
        stack = (type(stack) == "number" and stack or 2) + 1

        if msg then error(strformat("Usage: %s.%s(%s, name[, stack]) - ", tostring(tType), methodName, tostring(tType)) .. msg, stack) end

        if not (info[FLD_IC_NEWFTR] and info[FLD_IC_NEWFTR][name]) then
            if info[FLD_IC_OBJFTR] and info[FLD_IC_OBJFTR][name] ~= nil then
                error(strformat("Usage: %s.%s(%s, name[, stack]) - The %s's %q's definition is finished, can't change its priority", tostring(tType), methodName, tostring(tType), tostring(target), name), stack)
            else
                error(strformat("Usage: %s.%s(%s, name[, stack]) - The %s has no feature named %q", tostring(tType), methodName, tostring(tType), tostring(target), name), stack)
            end
        end

        info[FLD_IC_INHRTP] = info[FLD_IC_INHRTP] or _Cache()
        info[FLD_IC_INHRTP][name] = priority
    end

    local function setPriorityMethod(tType, target, name, methodName, priority, stack)
        local info, name, msg  = checkInfoWithName(tType, target, name)
        stack = (type(stack) == "number" and stack or 2) + 1

        if msg then error(strformat("Usage: %s.%s(%s, name[, stack]) - ", tostring(tType), methodName, tostring(tType)) .. msg, stack) end

        if not (info[FLD_IC_TYPMTD] and info[FLD_IC_TYPMTD][name]) then
            if info[FLD_IC_TYPMTD] and info[FLD_IC_TYPMTD][name] == false then
                error(strformat("Usage: %s.%s(%s, name[, stack]) - The %s's %q is static, can't change its priority", tostring(tType), methodName, tostring(tType), tostring(target), name), stack)
            else
                error(strformat("Usage: %s.%s(%s, name[, stack]) - The %s has no method named %q", tostring(tType), methodName, tostring(tType), tostring(target), name), stack)
            end
        end

        info[FLD_IC_INHRTP] = info[FLD_IC_INHRTP] or _Cache()
        info[FLD_IC_INHRTP][name] = priority
    end

    local function setPriorityMetaMethod(tType, target, name, methodName, priority, stack)
        local info, name, msg  = checkInfoWithName(tType, target, name)
        stack = (type(stack) == "number" and stack or 2) + 1

        if msg then error(strformat("Usage: %s.%s(%s, name[, stack]) - ", tostring(tType), methodName, tostring(tType)) .. msg, stack) end

        if not (info[FLD_IC_TYPMTM] and info[FLD_IC_TYPMTM][name]) then
            error(strformat("Usage: %s.%s(%s, name[, stack]) - The %s has no meta-method named %q", tostring(tType), methodName, tostring(tType), tostring(target), name), stack)
        end

        info[FLD_IC_INHRTP] = info[FLD_IC_INHRTP] or _Cache()
        info[FLD_IC_INHRTP][name] = priority
    end

    -- Buidler helpers
    local function getIfBuilderValue(self, name)
        -- Access methods
        local info = getICTargetInfo(environment.GetNameSpace(self))
        if info and info[name] then return info[name], true end
        return environment.GetValue(self, name)
    end

    local function getClsBuilderValue(self, name)
        -- Access methods
        local info = getICTargetInfo(environment.GetNameSpace(self))
        if info and info[name] then return info[name], true end
        return environment.GetValue(self, name)
    end

    local function setBuilderOwnerValue(owner, key, value, stack, notnewindex)

    end

    interface       = prototype "interface" {
        __index     = {
            ["AddExtend"]       = function(target, extendinterface, stack)
                addExtend(interface, target, extendinterface, stack)
            end;

            ["AddFeature"]      = function(target, ftype, name, definition, stack)
                addFeature(interface, target, ftype, name, definition, stack)
            end;

            ["AddMetaMethod"]   = function(target, name, func, stack)
                addMetaMethod(interface, target, name, func, stack)
            end;

            ["AddMethod"]       = function(target, name, func, stack)
                addMethod(interface, target, name, func, stack)
            end;

            ["BeginDefinition"] = function(target, stack)
                stack = (type(stack) == "number" and stack or 1) + 1

                target          = interface.Validate(target)
                if not target then error("Usage: interface.BeginDefinition(interface[, stack]) - interface not existed", stack) end

                if _ICInfo[target] and validateFlags(MOD_SEAL_IC, _ICInfo[target][FLD_IC_MOD]) then error(strformat("Usage: interface.BeginDefinition(interface[, stack]) - The %s is sealed, can't be re-defined", tostring(target)), stack) end
                if _BDInfo[target] then error(strformat("Usage: interface.BeginDefinition(interface[, stack]) - The %s's definition has already begun", tostring(target)), stack) end

                -- Only one thread can be allowed to define class or interface
                beginDefinition(target, stack + 1)

                local ninfo     = tblclone(_ICInfo[target], { [FLD_IC_SUPCACH] = false }, true)

                ninfo[FLD_IC_SUPCACH] = nil

                _BDInfo[target] = ninfo

                attribute.SaveAttributes(target, ATTRTAR_INTERFACE, stack + 1)
            end;

            ["EndDefinition"]   = function(target, stack)
                local ninfo     = _BDInfo[target]
                if not ninfo then return end

                stack = (type(stack) == "number" and stack or 1) + 1

                attribute.ApplyAttributes(target, ATTRTAR_INTERFACE, nil, nil, nil, unpack(ninfo, FLD_IC_STEXT))

                -- End new type feature's definition
                endDefinitionForNewFeatures(target, stack + 1)

                -- Re-generate the extended interfaces order list
                local lst       = generateSuperInfo(ninfo, _Cache())
                local idxIF     = FLD_IC_STEXT + #lst

                for i, extif in ipairs, lst, 0 do
                    ninfo[idxIF - i]= extif
                end

                _Cache(lst)

                generateTypeCaches(target, ninfo)

                -- End interface's definition
                _BDInfo[target] = nil

                -- Save as new interface's info
                _ICInfo[target] = ninfo

                attribute.AttachAttributes(target, ATTRTAR_INTERFACE)

                -- Release the lock, so other threads can be used to define interface or class
                endDefinition(target, stack + 1)

                return target
            end;

            ["RefreshDefinition"] = function(target, stack)
                stack = (type(stack) == "number" and stack or 1) + 1

                target          = interface.Validate(target)
                if not target then error("Usage: interface.RefreshDefinition(interface[, stack]) - interface not existed", stack) end
                if _BDInfo[target] then error(strformat("Usage: interface.RefreshDefinition(interface[, stack]) - The %s's definition has already begun", tostring(target)), stack) end

                -- Only one thread can be allowed to define class or interface
                beginDefinition(target, stack + 1)

                local ninfo     = tblclone(_ICInfo[target], { [FLD_IC_SUPCACH] = false }, true)

                ninfo[FLD_IC_SUPCACH] = nil

                -- Re-generate the extended interfaces order list
                local lst       = generateSuperInfo(ninfo, _Cache())
                local idxIF     = FLD_IC_STEXT + #lst

                for i, extif in ipairs, lst, 0 do
                    ninfo[idxIF - i]= extif
                end

                _Cache(lst)

                generateTypeCaches(target, ninfo)

                -- Save as new interface's info
                _ICInfo[target] = ninfo

                -- Release the lock, so other threads can be used to define interface or class
                endDefinition(target, stack + 1)

                return target
            end;

            ["GetDefault"]      = fakefunc;

            ["GetExtends"]      = function(target, cache)
                local info      = getICTargetInfo(target)
                if info then
                    if cache then
                        cache   = type(cache) == "table" and wipe(cache) or {}
                        for i   = #info, FLD_IC_STEXT, -1 do tinsert(cache, info[i]) end
                        return cache
                    else
                        local m = #info
                        local u = m - FLD_IC_STEXT
                        return function(self, n)
                            if type(n) == "number" and n >= 0 and n <= u then
                                local v = info[m - n]
                                if v then return n + 1, v end
                            end
                        end, target, 0
                    end
                elseif not cache then
                    return fakefunc, target, 0
                end
            end;

            ["GetFeature"]      = function(target, name)
                local info, def = getICTargetInfo(target)
                if info and type(name) == "string" then
                    local featr = info[FLD_IC_TYPFTR] and info[FLD_IC_TYPFTR][name]
                    if featr == false then featr = info[FLD_IC_STAFTR][name] end
                    return featr and getmetatable(featr).GetFeature(featr)
                end
            end;

            ["GetObjectFeature"]= function(target, name)
                local info, def = getICTargetInfo(target)
                if info and type(name) == "string" then
                    local featr = info[FLD_IC_TYPFTR] and info[FLD_IC_TYPFTR][name]
                    return featr and getmetatable(featr).GetFeature(featr)
                end
            end;

            ["GetStaticFeature"]= function(target, name)
                local info, def = getICTargetInfo(target)
                if info and type(name) == "string" then
                    local featr = info[FLD_IC_STAFTR] and info[FLD_IC_STAFTR][name]
                    return featr and getmetatable(featr).GetFeature(featr)
                end
            end;

            ["GetFeatures"]     = function(target, cache)
                local info      = getICTargetInfo(target)
                if info then
                    if cache then
                        cache   = type(cache) == "table" and wipe(cache) or {}

                        if info[FLD_IC_TYPFTR] then
                            for k, v in pairs, info[FLD_IC_TYPFTR] do
                                v = v or info[FLD_IC_STAFTR][k]
                                cache[k] = getmetatable(v).GetFeature(v)
                            end
                        end

                        return cache
                    elseif infop[FLD_IC_TYPFTR] then
                        local tf = info[FLD_IC_TYPFTR]
                        local sf = info[FLD_IC_STAFTR]
                        return function(self, n)
                            local n, v  = next(tf, n)
                            if n then
                                v       = v or sf[n]
                                return n, getmetatable(v).GetFeature(v)
                            end
                        end, target
                    end
                end
                if cache then
                    return type(cache) == "table" and cache or nil
                else
                    return fakefunc, target
                end
            end;

            ["GetObjectFeatures"]= function(target, cache)
                local info      = getICTargetInfo(target)
                if info then
                    if cache then
                        cache   = type(cache) == "table" and wipe(cache) or {}

                        if info[FLD_IC_TYPFTR] then
                            for k, v in pairs, info[FLD_IC_TYPFTR] do
                                if v then
                                    cache[k] = getmetatable(v).GetFeature(v)
                                end
                            end
                        end

                        return cache
                    elseif info[FLD_IC_TYPFTR] then
                        local tf = info[FLD_IC_TYPFTR]
                        return function(self, n)
                            local n, v  = next(tf, n)
                            while n and v == false do n, v = next(tf, n) end
                            if v then
                                return n, getmetatable(v).GetFeature(v)
                            end
                        end, target
                    end
                end
                if cache then
                    return type(cache) == "table" and cache or nil
                else
                    return fakefunc, target
                end
            end;

            ["GetStaticFeatures"]= function(target, cache)
                local info      = getICTargetInfo(target)
                if info then
                    if cache then
                        cache   = type(cache) == "table" and wipe(cache) or {}

                        if def and info[FLD_IC_NEWFTR] then for k, v in pairs, info[FLD_IC_NEWFTR] do if getmetatable(v).IsStatic(v) then cache[k] = getmetatable(v).GetFeature(v) end end end
                        if info[FLD_IC_STAFTR] then for k, v in pairs, info[FLD_IC_STAFTR] do if not cache[k] then cache[k] = getmetatable(v).GetFeature(v) end end end

                        return cache
                    else
                        local nf = def and info[FLD_IC_NEWFTR]
                        local sf = info[FLD_IC_STAFTR]
                        local bnf= nf
                        return function(self, n)
                            local v
                            if nf then
                                n, v    = next(nf, n)
                                while n and not getmetatable(v).IsStatic(v) do n, v = next(nf, n) end
                                if v then return n, getmetatable(v).GetFeature(v) end
                                nf, n   = nil
                            end
                            if sf then
                                n, v    = next(sf, n)
                                while n and bnf and bnf[n] do n, v = next(sf, n) end
                                if v then return n, getmetatable(v).GetFeature(v) end
                            end
                        end, target
                    end
                end
                if cache then
                    return type(cache) == "table" and cache or nil
                else
                    return fakefunc, target
                end
            end;

            ["GetMethod"]       = function(target, name)
                local info, def = getICTargetInfo(target)
                return info and type(name) == "string" and info[name] or nil
            end;

            ["GetObjectMethod"] = function(target, name)
                local info      = getICTargetInfo(target)
                local method    = info and type(name) == "string" and info[name]
                return method and info[FLD_IC_TYPMTD] and info[FLD_IC_TYPMTD][name] and method or nil
            end;

            ["GetStaticMethod"] = function(target, name)
                local info      = getICTargetInfo(target)
                local method    = info and type(name) == "string" and info[name]
                return method and not (info[FLD_IC_TYPMTD] and info[FLD_IC_TYPMTD][name]) and method or nil
            end;

            ["GetMethods"]      = function(target, cache)
                local info      = getICTargetInfo(target)
                if info then
                    if cache then
                        cache   = type(cache) == "table" and wipe(cache) or {}
                        for k, v in pairs, info do if type(k) == "string" then cache[k] = v end end
                        return cache
                    else
                        return function(self, n)
                            local v
                            n, v    = next(info, n)
                            while n and type(n) ~= "string" do n, v = next(info, n) end
                            if v then return n, v end
                        end, target
                    end
                end
                if cache then
                    return type(cache) == "table" and cache or nil
                else
                    return fakefunc, target
                end
            end;

            ["GetObjectMethods"]= function(target, cache)
                local info      = getICTargetInfo(target)
                if info then
                    local obm   = info[FLD_IC_TYPMTD]
                    if cache then
                        cache   = type(cache) == "table" and wipe(cache) or {}
                        if obm then for k, v in pairs, info do if obm[k] then cache[k] = v end end end
                        return cache
                    elseif obm then
                        return function(self, n)
                            local v
                            n, v    = next(info, n)
                            while n and not obm[n] do n, v = next(info, n) end
                            if v then return n, v end
                        end, target
                    end
                end
                if cache then
                    return type(cache) == "table" and cache or nil
                else
                    return fakefunc, target
                end
            end;

            ["GetStaticMethods"]= function(target, cache)
                local info      = getICTargetInfo(target)
                if info then
                    local obm   = info[FLD_IC_TYPMTD]
                    if cache then
                        cache   = type(cache) == "table" and wipe(cache) or {}
                        for k, v in pairs, info do if type(k) == "string" and not (obm and obm[k]) then cache[k] = v end end
                        return cache
                    else
                        return function(self, n)
                            local v
                            n, v    = next(info, n)
                            while n and (type(n) ~= "string" or obm and obm[n]) do n, v = next(info, n) end
                            if v then return n, v end
                        end, target
                    end
                end
                if cache then
                    return type(cache) == "table" and cache or nil
                else
                    return fakefunc, target
                end
            end;

            ["GetRequireClass"] = function(target)
                local info      = getICTargetInfo(target)
                return info and info[FLD_IC_REQCLS]
            end;

            ["IsSubType"]       = function(target, extendIF)
                if target == extendIF then return true end
                local info = getICTargetInfo(target)
                if info then for _, extif in ipairs, info, FLD_IC_STEXT - 1 do if extif == extendIF then return true end end end
                return false
            end;

            ["IsFinal"]         = function(target)
                local info      = getICTargetInfo(target)
                return info and validateFlags(MOD_FINAL_IC, info[FLD_IC_MOD]) or false
            end;

            ["IsSealed"]        = function(target)
                local info      = getICTargetInfo(target)
                return info and validateFlags(MOD_SEAL_IC, info[FLD_IC_MOD]) or false
            end;

            ["IsRequireFeature"]= function(target, name)
                local info      = getICTargetInfo(target)
                local feature   = info and (info[FLD_IC_NEWFTR] and info[FLD_IC_NEWFTR][name] or info[FLD_IC_TYPFTR] and info[FLD_IC_TYPFTR][name])
                return feature and getmetatable(feature).IsRequire(feature) or false
            end;

            ["IsRequireMethod"] = function(target, name)
                local info      = getICTargetInfo(target)
                return info and type(name) == "string" and info[name] and info[FLD_IC_TYPMTD] and info[FLD_IC_TYPMTD][name] == true or false
            end;

            ["IsRequireMetaMethod"] = function(target, name)
                local info      = getICTargetInfo(target)
                return info and type(name) == "string" and info[FLD_IC_TYPMTM] and info[FLD_IC_TYPMTM][name] == true or false
            end;

            ["IsStaticFeature"] = function(target, name)
                local info      = getICTargetInfo(target)
                local feature   = info and (info[FLD_IC_NEWFTR] and info[FLD_IC_NEWFTR][name] or info[FLD_IC_TYPFTR] and info[FLD_IC_TYPFTR][name])
                return feature and getmetatable(feature).IsStatic(feature) or false
            end;

            ["IsStaticMethod"]  = function(target, name)
                local info      = getICTargetInfo(target)
                return info and type(name) == "string" and info[name] and not (info[FLD_IC_TYPMTD] and info[FLD_IC_TYPMTD][name]) and true or false
            end;

            ["SetFinal"]        = function(target, stack)
                setModifiedFlag(interface, target, MOD_FINAL_IC, "SetFinal", stack)
            end;

            ["SetDispose"]      = function(target, func, stack)
                setDispose(interface, target, func, stack)
            end;

            ["SetInitializer"]  = function(target, func, stack)
                local info, def = getICTargetInfo(target)
                stack = (type(stack) == "number" and stack or 1) + 1

                if info then
                    if not def then error(strformat("Usage: interface.SetInitializer(interface, initializer[, stack]) - The %s's definition is finished", tostring(target)), stack) end
                    if type(func) ~= "function" then error("Usage: interface.SetInitializer(interface, initializer) - The initializer must be a function", stack) end
                    info[FLD_IC_INIT] = func
                else
                    error("Usage: interface.SetInitializer(interface, initializer[, stack]) - The interface is not valid", stack)
                end
            end;

            ["SetRequireClass"] = function(target, cls, stack)
                stack = (type(stack) == "number" and stack or 1) + 1

                if not interface.Validate(target) then error("Usage: interface.SetRequireClass(interface, requireclass[, stack]) - the interface is not valid", stack) end

                local info, def = getICTargetInfo(target)

                if info then
                    if not class.Validate(cls) then error("Usage: interface.SetRequireClass(interface, requireclass[, stack]) - the requireclass must be a class", stack) end
                    if not def then error(strformat("Usage: interface.SetRequireClass(interface, requireclass[, stack]) - The %s' definition is finished", tostring(target)), stack) end
                    if info[FLD_IC_REQCLS] and not class.IsSubType(cls, info[FLD_IC_REQCLS]) then error(strformat("Usage: interface.SetRequireClass(interface, requireclass[, stack]) - The requireclass must be %s's sub-class", tostring(info[FLD_IC_REQCLS])), stack) end

                    info[FLD_IC_REQCLS] = cls
                else
                    error("Usage: interface.SetRequireClass(interface, requireclass[, stack]) - The interface is not valid", stack)
                end
            end;

            ["SetRequireFeature"]= function(target, name)
                local info, def = getICTargetInfo(target)
                stack = (type(stack) == "number" and stack or 1) + 1

                if info then
                    if type(name) ~= "string" then error("Usage: interface.SetRequireFeature(interface, name[, stack]) - the name must be a string", stack) end
                    name = strtrim(name)
                    if name == "" then error("Usage: interface.SetRequireFeature(interface, name[, stack]) - The name can't be empty", stack) end
                    if not def then error(strformat("Usage: interface.SetRequireFeature(interface, name[, stack]) - The %s's definition is finished", tostring(target)), stack) end
                    if not (info[FLD_IC_NEWFTR] and info[FLD_IC_NEWFTR][name]) then
                        if info[FLD_IC_STAFTR] and info[FLD_IC_STAFTR][name] or info[FLD_IC_OBJFTR] and info[FLD_IC_OBJFTR][name] then
                            error(strformat("Usage: interface.SetRequireFeature(interface, name[, stack]) - The %s's %q's definition is finished, can't set as require", tostring(target), name), stack)
                        else
                            error(strformat("Usage: interface.SetRequireFeature(interface, name[, stack]) - The %s has no feature named %q", tostring(target), name), stack)
                        end
                    end

                    local feature = info[FLD_IC_NEWFTR][name]
                    getmetatable(feature).SetRequire(feature, stack + 1)
                else
                    error("Usage: interface.SetRequireFeature(interface, name[, stack]) - The interface is not valid", stack)
                end
            end;

            ["SetRequireMethod"]= function(target, name, stack)
                local info, def = getICTargetInfo(target)
                stack = (type(stack) == "number" and stack or 2) + 1

                if info then
                    if type(name) ~= "string" then error("Usage: interface.SetRequireMethod(interface, name[, stack]) - the name must be a string", stack) end
                    name = strtrim(name)
                    if name == "" then error("Usage: interface.SetRequireMethod(interface, name[, stack]) - The name can't be empty", stack) end
                    if not def then error(strformat("Usage: interface.SetRequireMethod(interface, name[, stack]) - The %s's definition is finished", tostring(target)), stack) end
                    if not info[name] then error(strformat("Usage: interface.SetRequireMethod(interface, name[, stack]) - The %s has no method named %q", tostring(target), name), stack) end
                    if not (info[FLD_IC_TYPMTD] and info[FLD_IC_TYPMTD][name]) then error(strformat("Usage: interface.SetRequireMethod(interface, name[, stack]) - The %q is a static method", name), stack) end

                    info[FLD_IC_TYPMTD][name] = true
                else
                    error("Usage: interface.SetRequireMethod(interface, name[, stack]) - The interface is not valid", stack)
                end
            end;

            ["SetRequireMetaMethod"] = function(target, name, stack)
                local info, def = getICTargetInfo(target)
                stack = (type(stack) == "number" and stack or 2) + 1

                if info then
                    if type(name) ~= "string" then error("Usage: interface.SetRequireMetaMethod(interface, name[, stack]) - the name must be a string", stack) end
                    name = strtrim(name)
                    if name == "" then error("Usage: interface.SetRequireMetaMethod(interface, name[, stack]) - The name can't be empty", stack) end
                    if not def then error(strformat("Usage: interface.SetRequireMetaMethod(interface, name[, stack]) - The %s's definition is finished", tostring(target)), stack) end
                    if not info[name] then error(strformat("Usage: interface.SetRequireMetaMethod(interface, name[, stack]) - The %s has no method named %q", tostring(target), name), stack) end
                    if not (info[FLD_IC_TYPMTD] and info[FLD_IC_TYPMTD][name]) then error(strformat("Usage: interface.SetRequireMetaMethod(interface, name[, stack]) - The %q is a static method", name), stack) end

                else
                    error("Usage: interface.SetRequireMetaMethod(interface, name[, stack]) - The interface is not valid", stack)
                end
            end;

            ["SetSealed"]       = function(target, stack)
                setModifiedFlag(interface, target, MOD_SEAL_IC, "SetSealed", stack)
            end;

            ["SetStaticFeature"]= function(target, name, stack)
                setStaticFeature(interface, target, name, stack)
            end;

            ["SetStaticMethod"] = function(target, name, stack)
                setStaticMethod(interface, target, name, stack)
            end;

            ["ValidateValue"]   = function(extendIF, value)
                local cls       = getmetatable(value)
                local info      = cls and getICTargetInfo(cls)
                if info then return info[FLD_IC_SUPINFO] and info[FLD_IC_SUPINFO][extendIF] and true or false end
                return false
            end;

            ["Validate"]        = function(target)
                return getmetatable(target) == interface and getICTargetInfo(target) and target or nil
            end;
        },
        __newindex  = readOnly,
        __call      = function(self, ...)
            local visitor, env, target, definition, keepenv, stack = GetTypeParams(interface, tinterface, ...)
            if not target then error("Usage: interface([env, ][name, ][definition, ][keepenv, ][, stack]) - the interface type can't be created", stack) end

            interface.BeginDefinition(target, stack + 1)

            local tarenv = prototype.NewObject(interfacebuilder)
            environment.Initialize(tarenv)
            environment.SetNameSpace(tarenv, target)
            environment.SetParent(env)

            if definition then
                tarenv(definition, stack + 1)
                return target
            else
                if not keepenv then setfenv(stack, tarenv) end
                return tarenv
            end
        end,
    }

    class           = prototype "calss" {
        __index     = {
            ["AddExtend"]       = function(target, extendinterface, stack)
                addExtend(class, target, extendinterface, stack)
            end;

            ["AddFeature"]      = function(target, ftype, name, definition, stack)
                addFeature(class, target, ftype, name, definition, stack)
            end;

            ["AddMetaMethod"]   = function(target, name, func, stack)
                addMetaMethod(class, target, name, func, stack)
            end;

            ["AddMethod"]       = function(target, name, func, stack)
                addMethod(class, target, name, func, stack)
            end;

            ["BeginDefinition"] = function(target, stack)
                stack = (type(stack) == "number" and stack or 1) + 1

                target          = interface.Validate(target)
                if not target then error("Usage: class.BeginDefinition(class[, stack]) - class not existed", stack) end

                local info      = _ICInfo[target]

                if info and validateFlags(MOD_SEAL_IC, info[FLD_IC_MOD]) then error(strformat("Usage: class.BeginDefinition(class[, stack]) - The %s is sealed, can't be re-defined", tostring(target)), stack) end
                if _BDInfo[target] then error(strformat("Usage: class.BeginDefinition(class[, stack]) - The %s's definition has already begun", tostring(target)), stack) end

                -- Only one thread can be allowed to define class or interface
                beginDefinition(target, stack + 1)

                local ninfo     = _Cache()

                ninfo[FLD_IC_SUPCACH]   = false
                ninfo[FLD_IC_SUPINFO]   = false
                ninfo[FLD_IC_OBJMTD]    = false
                ninfo[FLD_IC_OBJFTR]    = false
                ninfo[FLD_IC_OBJMTM]    = false
                tblclone(info, ninfo, true)
                ninfo[FLD_IC_SUPINFO]   = nil
                ninfo[FLD_IC_SUPCACH]   = nil
                ninfo[FLD_IC_OBJMTD]    = nil
                ninfo[FLD_IC_OBJFTR]    = nil
                ninfo[FLD_IC_OBJMTM]    = nil

                _BDInfo[target] = ninfo

                attribute.SaveAttributes(target, ATTRTAR_CLASS, stack + 1)
            end;

            ["EndDefinition"]   = function(target, stack)
                local ninfo     = _BDInfo[target]
                if not ninfo then return end

                stack = (type(stack) == "number" and stack or 1) + 1

                attribute.ApplyAttributes(target, ATTRTAR_CLASS, nil, nil, nil, unpack(ninfo, ninfo[FLD_IC_SUPCLS] and FLD_IC_SUPCLS or FLD_IC_STEXT))

                -- End new type feature's definition
                endDefinitionForNewFeatures(target, stack + 1)

                -- The init & dispose link for extended interfaces & super classes
                local initIdx   = FLD_IC_STINIT
                local dispIdx   = FLD_IC_ENDISP

                if validateFlags(MOD_ABSCLS_IC, ninfo[FLD_IC_MOD]) then
                    local lst   = generateSuperInfo(ninfo, _Cache())
                    local idxIF = FLD_IC_STEXT + #lst

                    for i, extif in ipairs, lst, 0 do
                        ninfo[idxIF - i]= extif
                    end

                    _Cache(lst)

                    ninfo[FLD_IC_SIMPCLS]   = nil
                    ninfo[FLD_IC_SUPINFO]   = nil
                    ninfo[FLD_IC_CTOR ]   = nil
                    ninfo[FLD_IC_CLINIT ]   = nil

                    if ninfo[FLD_IC_TYPMTD] then ninfo[FLD_IC_TYPMTD][IC_KEYWORD_DISPOB] = nil end
                else
                    -- Interface Order List, Super info cache
                    local lst, spc  = generateSuperInfo(ninfo, _Cache(), _Cache())

                    -- New meta table
                    local meta      = _Cache()
                    local rlCtor    = nil
                    local idxIF     = FLD_IC_STEXT + #lst

                    -- Save Dispose for super classes
                    for _, sinfo in ipairs, spc, 0 do
                        if sinfo[FLD_IC_DISPOSE] then
                            ninfo[dispIdx]  = sinfo[FLD_IC_DISPOSE]
                            dispIdx         = dispIdx - 1
                        end
                    end

                    -- Save class's dispose
                    if ninfo[FLD_IC_DISPOSE] then
                        ninfo[dispIdx]  = ninfo[FLD_IC_DISPOSE]
                        dispIdx         = dispIdx - 1
                    end

                    -- Save Initializer & Dispose for extended interfaces
                    for i, extif in ipairs, lst, 0 do
                        ninfo[idxIF - i]= extif

                        local sinfo     = spc[extif]
                        saveFeatureFromSuper(ninfo, sinfo, meta)

                        if sinfo[FLD_IC_INIT] then
                            ninfo[initIdx]  = sinfo[FLD_IC_INIT]
                            initIdx         = initIdx + 1
                        end

                        if sinfo[FLD_IC_DISPOSE] then
                            ninfo[dispIdx]  = sinfo[FLD_IC_DISPOSE]
                            dispIdx         = dispIdx - 1
                        end
                    end

                    _Cache(lst)

                    -- Save features from super classes
                    for i, sinfo in ipairs, spc, 0 do
                        rlCtor  = sinfo[FLD_IC_INIT] or rlCtor
                        saveFeatureFromSuper(ninfo, sinfo, meta)
                    end

                    -- Clear super classes info
                    if not next(spc) then _Cache(spc) spc = nil end

                    -- Saving informations
                    tblclone(ninfo[FLD_IC_TYPMTM], meta, false, true)
                    ninfo[FLD_IC_CLINIT]    = ninfo[FLD_IC_INIT] or rlCtor
                    ninfo[FLD_IC_SIMPCLS]   = not (ninfo[FLD_IC_CLINIT] or ninfo[FLD_IC_OBJFTR]) or nil
                    ninfo[FLD_IC_SUPINFO]   = spc
                    if ninfo[FLD_IC_OBJFTR] and not next(ninfo[FLD_IC_OBJFTR]) then _Cache(ninfo[FLD_IC_OBJFTR]) ninfo[FLD_IC_OBJFTR]= nil end

                    -- Always have a dispose method
                    local FLD_IC_STDISP     = dispIdx + 1
                    ninfo[FLD_IC_TYPMTD]    = ninfo[FLD_IC_TYPMTD] or _Cache()
                    ninfo[FLD_IC_TYPMTD][IC_KEYWORD_DISPOB] = function(self)
                        for i = FLD_IC_STDISP, FLD_IC_ENDISP do ninfo[i](self) end
                        rawset(wipe(self), "Disposed", true)
                    end

                    generateMetaIndex   (ninfo, meta)
                    generateMetaNewIndex(ninfo, meta)
                    meta[IC_KEYWORD_META]    = target

                    generateConstructor(ninfo, meta)
                end

                -- Clear non-used init & dispose
                while ninfo[initIdx] do ninfo[initIdx] = nil initIdx = initIdx + 1 end
                while ninfo[dispIdx] do ninfo[dispIdx] = nil dispIdx = dispIdx - 1 end

                -- Finish the definition
                _BDInfo[target] = nil

                -- Save as new class's info
                _ICInfo[target]   = ninfo

                -- Release the lock to allow other threads continue to define class or interface
                endDefinition(target, stack + 1)

                attribute.AttachAttributes(target, ATTRTAR_CLASS)

                return target
            end;

            ["GetDefault"]      = fakefunc;

            ["GetExtends"]      = interface.GetExtends;

            ["GetFeature"]      = interface.GetFeature;

            ["GetObjectFeature"]= interface.GetObjectFeature;

            ["GetStaticFeature"]= interface.GetStaticFeature;

            ["GetFeatures"]     = interface.GetFeatures;

            ["GetObjectFeatures"] = interface.GetObjectFeatures;

            ["GetStaticFeatures"] = interface.GetStaticFeatures;

            ["GetMethod"]       = interface.GetMethod;

            ["GetObjectMethod"] = interface.GetObjectMethod;

            ["GetStaticMethod"] = interface.GetStaticMethod;

            ["GetMethods"]      = interface.GetMethods;

            ["GetObjectMethods"]= interface.GetObjectMethods;

            ["GetStaticMethods"]= interface.GetStaticMethods;

            ["GetSuperClass"]   = function(target)
                local info      = getICTargetInfo(target)
                return info and info[FLD_IC_SUPCLS]
            end;

            ["IsSubType"]       = function(target, supertype)
                if target == supertype then return true end
                local info = getICTargetInfo(target)
                if info then
                    local sinfo = info[FLD_IC_SUPINFO]
                    if sinfo then return sinfo[supertype] and true or false end

                    if class.Validate(supertype) then
                        while info and info[FLD_IC_SUPCLS] ~= supertype do
                            info= getICTargetInfo(info[FLD_IC_SUPCLS])
                        end
                        if info then return true end
                    else
                        for _, extif in ipairs, info, FLD_IC_STEXT - 1 do if extif == supertype then return true end end
                    end
                end
                return false
            end;

            ["IsAbstract"]      = function(target)
                local info      = getICTargetInfo(target)
                return info and validateFlags(MOD_ABSCLS_IC, info[FLD_IC_MOD]) or false
            end;

            ["IsAutoCache"]     = function(target)
                local info      = getICTargetInfo(target)
                return info and validateFlags(MOD_ATCACHE_IC, info[FLD_IC_MOD]) or false
            end;

            ["IsFinal"]         = interface.IsFinal;

            ["IsObjMethodAttrEnabled"] = function(target)
                local info      = getICTargetInfo(target)
                return info and validateFlags(MOD_OBJMDAT_IC, info[FLD_IC_MOD]) or false
            end;

            ["IsOldSuperStyleClass"] = function(target)
                local info      = getICTargetInfo(target)
                return info and validateFlags(MOD_ODSUPER_IC, info[FLD_IC_MOD]) or false
            end;

            ["IsRawSetBlocked"] = function(target)
                local info      = getICTargetInfo(target)
                return info and validateFlags(MOD_NRAWSET_IC, info[FLD_IC_MOD]) or false
            end;

            ["IsSealed"]        = interface.IsSealed;

            ["IsSimpleClass"]   = function(target)
                local info      = getAttributeInfo(target)
                return info and (info[FLD_IC_SIMPCLS] or validateFlags(MOD_ASSPCLS_IC, info[FLD_IC_MOD])) or false
            end;

            ["IsSimpleVersion"] = function(target)
                local info      = getICTargetInfo(target)
                return info and validateFlags(MOD_SIMPVER_IC, info[FLD_IC_MOD]) or false
            end;

            ["IsStaticFeature"] = interface.IsStaticFeature;

            ["IsStaticMethod"]  = interface.IsStaticMethod;

            ["IsThreadSafe"]    = function(target)
                local info      = getICTargetInfo(target)
                return info and validateFlags(MOD_THDSAFE_IC, info[FLD_IC_MOD]) or false
            end;

            ["SetAbstract"]     = function(target, stack)
                setModifiedFlag(class, target, MOD_ABSCLS_IC, "SetAbstract", stack)
            end;

            ["SetAutoCache"]    = function(target, stack)
                setModifiedFlag(class, target, MOD_ATCACHE_IC, "SetAutoCache", stack)
            end;

            ["SetAsSimpleClass"]= function(target, stack)
                setModifiedFlag(class, target, MOD_ASSPCLS_IC, "SetAsSimpleClass", stack)
            end;

            ["SetConstructor"]  = function(target, func, stack)
                local info, def = getICTargetInfo(target)
                stack = (type(stack) == "number" and stack or 1) + 1

                if info then
                    if not def then error(strformat("Usage: class.SetConstructor(class, constructor[, stack]) - The %s's definition is finished", tostring(target)), stack) end
                    if type(func) ~= "function" then error("Usage: class.SetConstructor(class, constructor) - The constructor must be a function", stack) end

                    attribute.SaveAttributes(func, ATTRTAR_CLASS_CONSTRUCTOR, stack + 1)
                    func = attribute.ApplyAttributes(func, ATTRTAR_CLASS_CONSTRUCTOR, nil, target, name)

                    info[FLD_IC_INIT] = func

                    attribute.AttachAttributes(func, ATTRTAR_CLASS_CONSTRUCTOR, target, name)
                else
                    error("Usage: class.SetConstructor(class, constructor[, stack]) - The class is not valid", stack)
                end
            end;

            ["SetDispose"]      = function(target, func, stack)
                setDispose(class, target, func, stack)
            end;

            ["SetFinal"]        = function(target, stack)
                setModifiedFlag(class, target, MOD_FINAL_IC, "SetFinal", stack)
            end;

            ["SetObjMethodAttrEnabled"] = function(target, stack)
                setModifiedFlag(class, target, MOD_OBJMDAT_IC, "SetObjMethodAttrEnabled", stack)
            end;

            ["SetOldSuperStyle"]= function(target, stack)
                setModifiedFlag(class, target, MOD_ODSUPER_IC, "SetOldSuperStyle", stack)
            end;

            ["SetRawSetBlocked"]= function(target, stack)
                setModifiedFlag(class, target, MOD_NRAWSET_IC, "SetRawSetBlocked", stack)
            end;

            ["SetSealed"]       = function(target, stack)
                setModifiedFlag(class, target, MOD_SEAL_IC, "SetSealed", stack)
            end;

            ["SetSimpleVersion"]= function(target, stack)
                setModifiedFlag(class, target, MOD_SIMPVER_IC, "SetSimpleVersion", stack)
            end;

            ["SetSuperClass"]   = function(target, cls, stack)
                stack = (type(stack) == "number" and stack or 1) + 1

                if not class.Validate(target) then error("Usage: class.SetSuperClass(class, superclass[, stack]) - the class is not valid", stack) end

                local info, def = getICTargetInfo(target)

                if info then
                    if not class.Validate(cls) then error("Usage: class.SetSuperClass(class, superclass[, stack]) - the superclass must be a class", stack) end
                    if not def then error(strformat("Usage: class.SetSuperClass(class, superclass[, stack]) - The %s' definition is finished", tostring(target)), stack) end
                    if info[FLD_IC_SUPCLS] and info[FLD_IC_SUPCLS] ~= cls then error(strformat("Usage: class.SetSuperClass(class, superclass[, stack]) - The %s already has a super class", tostring(target)), stack) end

                    if info[FLD_IC_SUPCLS] then return end

                    addSuperType(info, target, cls)
                else
                    error("Usage: class.SetSuperClass(class, superclass[, stack]) - The class is not valid", stack)
                end
            end;

            ["SetStaticFeature"]= function(target, name, stack)
                setStaticFeature(class, target, name, stack)
            end;

            ["SetStaticMethod"] = function(target, name, stack)
                setStaticMethod(class, target, name, stack)
            end;

            ["SetThreadSafe"]   = function(target, stack)
                setModifiedFlag(class, target, MOD_THDSAFE_IC, "SetThreadSafe", stack)
            end;

            ["ValidateValue"]   = function(cls, value)
                local ocls      = getmetatable(value)
                if not ocls     then return false end
                if ocls == cls  then return true end
                local info      = getICTargetInfo(ocls)
                return info and info[FLD_IC_SUPINFO] and info[FLD_IC_SUPINFO][cls] and true or false
            end;

            ["Validate"]        = function(target)
                return getmetatable(target) == class and getICTargetInfo(target) and target or nil
            end;
        },
        __newindex  = readOnly,
        __call      = function(self, ...)
            local visitor, env, target, definition, keepenv, stack = GetTypeParams(class, tclass, ...)
            if not target then error("Usage: class([env, ][name, ][definition, ][keepenv, ][, stack]) - the class type can't be created", stack) end

            class.BeginDefinition(target, stack + 1)

            local tarenv = prototype.NewObject(classbuilder)
            environment.Initialize(tarenv)
            environment.SetNameSpace(tarenv, target)
            environment.SetParent(env)

            if definition then
                tarenv(definition, stack + 1)
                return target
            else
                if not keepenv then setfenv(stack, tarenv) end
                return tarenv
            end
        end,
    }

    tinterface      = prototype "tinterface" (tnamespace, {
        __index     = function(self, key)
            if type(key) == "string" then
                -- Access methods
                local info  = _ICInfo[self]
                if info then
                    -- Meta-methods
                    local oper  = META_KEYS[key]
                    if oper then return info[FLD_IC_TYPMTM] and info[FLD_IC_TYPMTM][oper] or nil end

                    -- Static or object methods
                    oper  = info[key]
                    if oper then return oper end

                    -- Static features
                    oper  = info[FLD_IC_STAFTR] and info[FLD_IC_STAFTR][key]
                    if oper then return oper:Get(self) end
                end

                -- Access child-namespaces
                return namespace.GetNameSpace(self, key)
            end
        end,
        __newindex  = function(self, key, value)
            if type(key) == "string" then
                local info  = _ICInfo[self]

                if info then
                    -- Static features
                    local oper  = info[FLD_IC_STAFTR] and info[FLD_IC_STAFTR][key]
                    if oper then oper:Set(self, value) return end

                    -- Try add methods
                    if type(value) == "function" then
                        interface.AddMethod(self, key, value, 3)
                        return
                    end
                end
            end

            error(strformat("The %s is readonly", tostring(self)), 2)
        end,
        __call      = function(self, init)
            local info  = _ICInfo[self]
            if type(init) == "string" then
                local ret, msg = struct.ValidateValue(Lambda, init)
                if msg then error(strformat("Usage: %s(init) - ", tostring(self)) .. (type(msg) == "string" and strgsub(msg, "%%s%.?", "init") or "the init is not valid."), 2) end
                init    = ret
            end

            if type(init) == "function" then
                if not info[FLD_IC_ONEVRM] then error(strformat("Usage: %s(init) - the interface isn't an one method required interface", tostring(self)), 2) end
                init    = { [info[FLD_IC_ONEVRM]] = init }
            end

            if init and type(init) ~= "table" then error(strformat("Usage: %s(init) - the init can only be lambda expression, function or table", tostring(self)), 2) end

            local aycls = info[FLD_IC_ANYMSCL]

            if not aycls then
                local r = getUniqueReqMethod(info)
                for k in pairs, r do r[k] = fakefunc end
                r[1]    = self
                aycls   = class(r, true)
                info[FLD_IC_ANYMSCL] = aycls
            end

            return aycls(init)
        end,
        __metatable = interface,
    })

    tclass          = prototype "tclass" (tinterface, {
        __newindex  = function(self, key, value)
            if type(key) == "string" then
                local info  = _ICInfo[self]

                if info then
                    -- Static features
                    local oper  = info[FLD_IC_STAFTR] and info[FLD_IC_STAFTR][key]
                    if oper then oper:Set(self, value) return end

                    -- Try add methods
                    if type(value) == "function" then
                        class.AddMethod(self, key, value, 3)
                        return
                    end
                end
            end

            error(strformat("The %s is readonly", tostring(self)), 2)
        end,
        __call      = function(self, ...)
            local info  = _ICInfo[self]
            local obj   = info[FLD_IC_CTOR](...)
            return obj
        end,
        __metatable = class,
    })

    tSuperInterface = prototype "tSuperInterface" {
        __index     = function(self, key)
            local t = type(key)

            if t == "string" then
                local obj = _SuperObj[self]
                if obj then
                    _SuperObj[self] = nil
                    local info  = getICTargetInfo(getmetatable(obj))
                    if not info then error("Usage: Super[obj].Method(obj, [...]) - Can't figure out the obj's class", 2) end
                    return getSuperMethod(info, key, _SuperMap[self])
                else
                    local info  = _ICInfo[_SuperMap[self]]
                    if not info then error("Usage: Super.Method(obj, [...]) - Can't figure out the type that the super represent", 2) end
                    local f     = info[FLD_IC_SUPCACH][key]
                    if not f then
                        if META_KEYS[key] then
                            f   = getSuperMetaMethod(info, key)
                        else
                            f   = getSuperMethod(info, key) or getSuperFeature(info, key)
                        end
                        info[FLD_IC_SUPCACH][key] = f
                    end
                    if type(f) ~= "function" then error(strformat("No method named %q can be find in Super", key), 2) end
                    return f
                end
            elseif t == "table" then
                _SuperObj[self] = key
                return self
            end
        end,
        __newindex  = function(self, key, value)
            if type(key) == "string" then
                local obj = _SuperObj[self]
                if not obj then error("Usage: Super[obj].PropA = value", 2) end
                _SuperObj[self] = nil
            end
        end,
        __metatable = interface,
    }

    tSuperClass     = prototype "tSuperClass" (tSuperInterface, {
        __call      = function(self, obj, ...)

        end,
        __metatable = class,
    })

    tThisClass      = prototype "tThisClass" {
        __call      = function(self, obj, ...)

        end,
        __metatable = class,
    }

    interfacebuilder= prototype "interfacebuilder" {
        __index     = function(self, key)
            local val, cache = getBuilderValue(self, key)

            -- Access methods
            local info  = getICTargetInfo(environment.GetNameSpace(self))
            local m     = info and (info[name] or info[FLD_IC_TYPMTD] and info[FLD_IC_TYPMTD][name])
            if m then return m, true end
            return environment.GetValue(self, name)
            if val ~= nil and cache and not _BDInfo[environment.GetNameSpace(self)] then
                rawset(self, key, val)
            end
            return val
        end,
        __newindex  = function(self, key, value)
            local owner = environment.GetNameSpace(self)
            if _BDInfo[owner] then
                if setBuilderOwnerValue(owner, key, value, 3) then
                    return
                end
            end
            return rawset(self, key, value)
        end,
        __call      = function(self, definition, stack)
            if not definition then error("Usage: struct([env, ][name, ][stack]) (definition) - the definition is missing", stack) end

            local owner = environment.GetNameSpace(self)
            if not owner then error("The struct's definition is finished", stack) end

            stack = stack + 1

            if type(definition) == "function" then
                definition(self)
            else
                -- Index key first
                for i, v in ipairs, definition, 0 do
                    setBuilderOwnerValue(owner, i, v, stack)
                end

                for k, v in pairs, definition do
                    if type(k) == "string" then
                        setBuilderOwnerValue(owner, k, v, stack, true)
                    end
                end
            end

            setfenv(stack - 1, environment.GetParent(self) or _G)
            struct.EndDefinition(owner, stack)

            return owner
        end,
    }

    classbuilder    = prototype "classbuilder" ( interfacebuilder, {

    })

    typefeature     = prototype "typefeature" {
        __index     = {
            ["New"]             = function(owner, name, definition, stack)
            end;
            ["Validate"]        = function(feature)
            end;
            ["ApplyAttributes"] = function(feature, owner, name, ...)
            end;
        },
        __newindex  = readOnly
    }
end

-------------------------------------------------------------------------------
--                                   event                                   --
-------------------------------------------------------------------------------
do
    -----------------------------------------------------------------------
    --                         attribute targets                         --
    -----------------------------------------------------------------------
    ATTRTAR_EVENT               = attribute.RegisterTargetType("Event")

    -----------------------------------------------------------------------
    --                          private storage                          --
    -----------------------------------------------------------------------
    local _EvtInfo  = setmetatable({}, WEAK_KEY)

    local FD_NAME   = 0
    local FD_OWNER  = 1
    local FD_STATIC = 2
    local FD_INDEF  = 3

    -- Key feature : event "Name"
    event           = prototype "event" (typefeature, {
        __index     = {
            ["BeginDefinition"] = function(owner, name, definition, super, stack)
                local evt       = prototype "name" (tevent)
                _EvtInfo[evt]   = setmetatable({ [FD_NAME] = name, [FD_OWNER] = owner, [FD_INDEF] = true }, WEAK_KEY)

                attribute.SaveAttributes(evt, ATTRTAR_EVENT, stack + 1)
                attribute.ApplyAttributes  (evt, ATTRTAR_EVENT, nil, owner, name, super)

                return evt
            end;

            ["EndDefinition"]   = function(feature, owner, name)
                attribute.AttachAttributes (feature, ATTRTAR_EVENT, owner, name)

                local info      = _EvtInfo[feature]
                if info then info[FD_INDEF] = nil end
            end;

            ["GetFeature"]      = function(feature) return feature end;

            ["Invoke"]          = function(feature, obj, ...)
                local info      = _EvtInfo[feature]
                local handler   = info and info[obj]
                if handler then

                end
            end;

            ["IsStatic"]        = function(feature)
                local info      = _EvtInfo[feature]
                return info and info[FD_STATIC] or false
            end;

            ["SetStatic"]       = function(feature, stack)
                stack           = type(stack) == "number" and stack or 2
                local info      = _EvtInfo[feature]
                if info then
                    if info[FD_INDEF] then
                        info[FD_STATIC] = true
                    elseif not info[FD_STATIC] then
                        error("Usage: event.SetStatic(event[, stack]) - The event's definition is finished", stack)
                    end
                else
                    error("Usage: event.SetStatic(event[, stack]) - The event object is not valid", stack)
                end
            end;

            ["Validate"]        = function(feature)
                return _EvtInfo[feature] and feature or nil
            end;
        },
        __call      = function(self, ...)
            if self == event then
                local owner,env, name, definition, flag, stack = GetFeatureParams(event, ...)
                if not owner then error([[Usage: event "name" - can't be used here.]], stack) end
                if type(name) ~= "string" then error([[Usage: event "name" - the name must be a string.]], stack) end
                name = strtrim(name)
                if name == "" then error([[Usage: event "name" - the name can't be an empty string.]], stack) end

                getmetatable(owner).AddFeature(owner, event, name, definition, stack + 1)
            else
                error([[Usage: event "name" - can only be used by event command.]], stack)
            end
        end;
    })

    tevent          = prototype "tevent" {
        __call      = event.Invoke,
    }
end

-------------------------------------------------------------------------------
--                                 property                                  --
-------------------------------------------------------------------------------
do
    -----------------------------------------------------------------------
    --                         attribute targets                         --
    -----------------------------------------------------------------------
    ATTRTAR_PROPERTY            = attribute.RegisterTargetType("Property")

    -----------------------------------------------------------------------
    --                          private storage                          --
    -----------------------------------------------------------------------

    -----------------------------------------------------------------------
    --                             property                              --
    -----------------------------------------------------------------------
    -- Key feature : property "Name" { Type = String, Default = "Anonymous" }
    property        = prototype "property" {
        __index     = {
            ["New"]             = function(self, owner, name)

            end;

            ["GetFeature"]      = function(feature) return nil end;
        },
        __call      = function(self, ...)
            if self == property then
                local owner, env, name, definition, flag, stack = GetFeatureParams(property, ...)
                if not owner or not tarenv then error([[Usage: property "name" {...} - can't be used here.]], stack) end
                if type(name) ~= "string" then error([[Usage: property "name" {...} - the name must be a string.]], stack) end
                name = strtrim(name)
                if name == "" then error([[Usage: property "name" {...} - the name can't be an empty string.]], stack) end

                if definition then
                    if type(definition) ~= "table" then error([[Usage: property ("name", {...}) - the definition must be a table.]], stack) end
                    getmetatable(owner).AddFeature(owner, property, name, definition, stack + 1)
                else
                    return prototype.NewObject(property, { name = name, owner = owner })
                end
            else
                local owner, name       = self.owner, self.name
                local definition, stack = ...

                if type(name) ~= "string" then error([[Usage: property "name" {...} - the name must be a string.]], stack) end
                name = strtrim(name)
                if name == "" then error([[Usage: property "name" {...} - the name can't be an empty string.]], stack) end
                if type(definition) ~= "table" then error([[Usage: property ("name", {...}) - the definition must be a table.]], stack) end

                getmetatable(owner).AddFeature(owner, property, name, definition, stack + 1)
            end
        end,
    }

    tproperty       = prototype "tproperty" { __metatable = property }
end

-------------------------------------------------------------------------------
--                           Feature Installation                            --
-------------------------------------------------------------------------------
do
    environment.RegisterGlobalKeyword {
        import          = import,
        enum            = enum,
        struct          = struct,
        class           = class,
        interface       = interface,
    }

    environment.RegisterContextKeyword(structbuilder, {
        member          = member,
        endstruct       = PLOOP_PLATFORM_SETTINGS.TYPE_DEFINITION_WITH_OLD_STYLE and endstruct,
    })

    environment.RegisterContextKeyword(interfacebuilder, {
        extend          = extend,
        event           = event,
        property        = property,
        endinterface    = PLOOP_PLATFORM_SETTINGS.TYPE_DEFINITION_WITH_OLD_STYLE and endinterface,
    })

    environment.RegisterContextKeyword(classbuilder, {
        inherit         = inherit,
        extend          = extend,
        event           = event,
        property        = property,
        endclass        = PLOOP_PLATFORM_SETTINGS.TYPE_DEFINITION_WITH_OLD_STYLE and endclass,
    })

    _G.PLoop = prototype "PLoop" {
        __index = {
            namespace   = namespace,
            enum        = enum,
            import      = import,
            environment = environment,
        }
    }

    _G.namespace        = namespace
    _G.enum             = enum
    _G.import           = import
    _G.struct           = struct
end

-------------------------------------------------------------------------------
--                                  System                                   --
-------------------------------------------------------------------------------
do

end

return ROOT_NAMESPACE