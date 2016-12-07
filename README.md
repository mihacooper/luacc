# LuaCC - Lua Code Combiner

LuaCC is a command line tool that allows you combine multiple Lua files into single one without any changes of your source code.

## How it works?

LuaCC principle is based on Lua [package.loaders](https://www.lua.org/manual/5.1/manual.html#pdf-package.loaders) approach. LuaCC obtain the *main* file of the application and any number of *additional Lua modules*. The *main* file is used as a base of result script (it's content is copied *as is*) and content of each *additional Lua module* is saved to result script as a function to special table with a key equals to the name of module.

After that the content of the modules embedded into the the table is loading using a special **internal loader** function. **Internal loader** replaces the default **package.loaders[2]** which actually searches for \*.lua modules using pathes from [package.path](http://lua-users.org/wiki/PackagePath). By default **internal loader** does not completely delete **package.loaders[2]**, firstly **internal loader** tries to find out the required module among the embedded modules and if it was not found **internal loader** will call the standard **package.loaders[2]** to load the module from filesystem. 

## Usage
```
luacc -o <output> [-i <include>] [-p <position>] <main> [modules] ...
```
  * **output** - output filename  
    *Example*: `luacc ... -o /path/to/result.lua`
  * **position**
      * By default LuaCC  insert generated code at the very beginning of result file but if first line pf main file is starting with `#!` LuaCC leave it first
      * **0..N** - number of main file's line after which LuaCC should place the generated code  
        *Example*: `luacc ... -p 10`
      * **"..."** - string value determines the position of generated code  
        *Example*: `luacc ... -p "LuaCC code block"`  
        *Note*: LuaCC will looking for *"--LuaCC code block"* comment in main file and will replace it with generated code  
        *Note*: LuaCC searches till **first match**, LuaCC matches only the **whole string** 
  * **\<main\>** - the main file of application which will copied to result file 'as is'  
    *Example*: `luacc ... path.to.main.file`  
    *Note*: main file should always be first positional argument  
    *Note*: use a Lua module path notation to specify this parameter
  * **\<modules\>** - additional modules which should be available with **require("...")** function call  
    *Example*: `luacc ... path.to.main.file path.to.module1 path.to.module2 ...`
    *Note*: use a Lua module path notation to specify this parameter
    *Note*: the specified name should be the same as you use in your require("") functions
  * **include** - additional search paths for *main* file and *modules*
    *Example*: `luacc ... -i /one/path/to/folder/with/modules -i /another/path/to/folder/with/modules`  
    *Note*: LuaCC uses includes in the same way as [package.path](http://lua-users.org/wiki/PackagePath). Firstly it tries to find out the module using the current path and if it's not found LuaCC searches the module using each include path in specified order

### Example
Let's show you example of project consists of main file `main.lua` and 2 modules: `module1.lua` and `module2.lua`
```
/path/to/project
    |
    |-main.lua
    |-subfolder
        |
        |-module1.lua
```
```
/path/to/external/modules
    |
    |-module2.lua
```

Below you can see the source code of these files:
**main.lua**
```lua
print "Main module"

local module1 = require "subfolder.module1"
local module2 = require "module2"

print("Module says:", module1.name)
print("Module says:", module2.name)
```

**module1.lua**
```lua
print "Module1 was loaded"
return { name = "My name is Module1" }
```

**module2.lua**
```lua
print "Module2 was loaded"
return { name = "My name is Module2" }
```
---
To combine the files use the command below:
```bash
$ lua luacc.lua -o myapp.lua -i /path/to/project -i /path/to/external/modules main subfolder.module1 module2 
```

And now just execute the result script:
```bash
$ lua myapp.lua
Main module
Module1 was loaded
Module2 was loaded
Module says: My name is Module1
Module says: My name is Module2
```
## Limitations

Generally, LuaCC does not use global variables and does not affect the logic of your application, but considering the fact that LuaCC override stadard [package.loaders](https://www.lua.org/manual/5.1/manual.html#pdf-package.loaders) you should be careful to override it in your application.

LuaCC works with Lua 5.1 and Lua 5.2 and I think it can work with a older versions, but it can be a problem if you'r using obsolete Lua [module (old version)](http://lua-users.org/wiki/ModulesTutorial) function.
