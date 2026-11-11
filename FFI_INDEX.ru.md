# FFI: справочник функций

Сигнатуры, параметры и результаты всех доступных методов. Обозначения: `?` — необязательный аргумент или nil; `[]` — массив; `...` — переменное число аргументов/результатов. Типы Lua и имена ошибок сохраняют написание API.

Правила вызова и примеры находятся в руководстве соответствующего модуля. Описание структуры результата: [типы данных](TYPES.ru.md). Lua-значения возвращаются по порядку; несколько результатов не являются одной таблицей.

## Модули

- [ffi](#ffi) — [Native FFI](FFI.ru.md).

## ffi

Руководство: [Native FFI](FFI.ru.md).

### ffi.abi

`ffi.abi(flag)`

| Аргумент | Тип и условия |
|---|---|
| `flag` | string |

Результаты:

- boolean

### ffi.addressof

`ffi.addressof(value)`

| Аргумент | Тип и условия |
|---|---|
| `value` | CData |

Результаты:

- CData pointer

### ffi.alignof

`ffi.alignof(value)`

| Аргумент | Тип и условия |
|---|---|
| `value` | CData&#124;string&#124;CType |

Результаты:

- integer

### ffi.cast

`ffi.cast(ctype, value)`

| Аргумент | Тип и условия |
|---|---|
| `ctype` | string&#124;CType |
| `value` | any |

Результаты:

- CData

### ffi.cdef

`ffi.cdef(declarations, ...)`

| Аргумент | Тип и условия |
|---|---|
| `declarations` | string |

Значения не возвращаются.

### ffi.copy

`ffi.copy(destination, source, length)`

| Аргумент | Тип и условия |
|---|---|
| `destination` | CData |
| `source` | CData&#124;string |
| `length?` | integer |

Значения не возвращаются.

### ffi.errno

`ffi.errno(value)`

| Аргумент | Тип и условия |
|---|---|
| `value?` | integer |

Результаты:

- integer

### ffi.eval

`ffi.eval(literal)`

| Аргумент | Тип и условия |
|---|---|
| `literal` | string Numeric literal; not a C expression evaluator. |

Результаты:

- CData

### ffi.fill

`ffi.fill(destination, length, byte)`

| Аргумент | Тип и условия |
|---|---|
| `destination` | CData |
| `length` | integer |
| `byte?` | integer |

Значения не возвращаются.

### ffi.gc

`ffi.gc(value, finalizer)`

| Аргумент | Тип и условия |
|---|---|
| `value` | CData |
| `finalizer?` | fun(value: CData) nil removes finalizer. |

Результаты:

- CData

### ffi.istype

`ffi.istype(ctype, value)`

| Аргумент | Тип и условия |
|---|---|
| `ctype` | string&#124;CType |
| `value` | CData |

Результаты:

- boolean

### ffi.load

`ffi.load(name, global)`

| Аргумент | Тип и условия |
|---|---|
| `name` | string UTF-8 DLL name/path on Windows. |
| `global?` | boolean |

Результаты:

- CLibrary

### ffi.metatype

`ffi.metatype(ctype, metatable)`

| Аргумент | Тип и условия |
|---|---|
| `ctype` | string&#124;CType |
| `metatable` | table |

Результаты:

- CType

### ffi.new

`ffi.new(ctype, ...)`

| Аргумент | Тип и условия |
|---|---|
| `ctype` | string&#124;CType |

Результаты:

- CData

### ffi.offsetof

`ffi.offsetof(ctype, field)`

| Аргумент | Тип и условия |
|---|---|
| `ctype` | string&#124;CType |
| `field` | string |

Результаты:

- integer?

### ffi.sizeof

`ffi.sizeof(value, ...)`

| Аргумент | Тип и условия |
|---|---|
| `value` | CData&#124;string&#124;CType |

Результаты:

- integer? nil when size is unknown.

### ffi.string

`ffi.string(value, length)`

| Аргумент | Тип и условия |
|---|---|
| `value` | CData |
| `length?` | integer |

Результаты:

- string

### ffi.tonumber

`ffi.tonumber(value)`

| Аргумент | Тип и условия |
|---|---|
| `value` | CData&#124;number&#124;string |

Результаты:

- number?

### ffi.toretval

`ffi.toretval(value)`

| Аргумент | Тип и условия |
|---|---|
| `value` | CData |

Результаты:

- any

### ffi.type

`ffi.type(value)`

| Аргумент | Тип и условия |
|---|---|
| `value` | any |

Результаты:

- string 'cdata' for CData/CType, otherwise the ordinary Lua type.

### ffi.typeof

`ffi.typeof(ctype, ...)`

| Аргумент | Тип и условия |
|---|---|
| `ctype` | string&#124;CType |

Результаты:

- CType

