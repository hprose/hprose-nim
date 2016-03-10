############################################################
#                                                          #
#                          hprose                          #
#                                                          #
# Official WebSite: http://www.hprose.com/                 #
#                   http://www.hprose.org/                 #
#                                                          #
############################################################

############################################################
#                                                          #
# hprose/io/classmanager.nim                               #
#                                                          #
# hprose classmanager for Nim                              #
#                                                          #
# LastModified: Mar 9, 2016                                #
# Author: Ma Bingyao <andot@hprose.com>                    #
#                                                          #
############################################################

import typeinfo, typetraits, hashes, tables
import tags, reader

# type
#     Unserializer* = ref object of RootObj
#         init*: proc(): Any
#         setRef*: proc(reader: Reader, obj: Any)
#         setField*: proc(reader: Reader, obj: Any, name: string)
#
# proc hash*(o: Unserializer): int = hash(cast[pointer](o))
#
# proc newUnserializer(): Unserializer = new(result)

var nameCache = initTable[string, string]()
# var typeCache = initTable[string, Unserializer]()

proc register*[T: tuple|object](alias: string = nil) =
    var a = alias
    if a.isNil: a = name(T)
    var n = name(T)
    when T is ref|ptr:
        var x: T
        n = name(type(x[]))
    if a notin nameCache:
        nameCache[n] = a
        # var unserializer = newUnserializer()
        # unserializer.init = proc(): Any =
        #     var o: ref T
        #     new(o)
        #     result = toAny(o)
        # unserializer.setRef = proc(reader: Reader, obj: Any) =
        #     when T is ref:
        #         reader.setRef(getPointer(obj))
        #     else:
        #         reader.setRef(nil)
        # unserializer.setField = proc(reader: Reader, obj: Any, name: string) =
        #     obj[name] = toAny(reader.unserialize[type(T()[name])]())
        # typeCache[alias] = unserializer

proc getAlias*[T: tuple|object](): string =
    var n = name(T)
    when T is ref|ptr:
        var x: T
        n = name(type(x[]))
    if n in nameCache:
        return nameCache[n]
    else:
        when T is object|ref object:
            register[T]()
            return name(T)
        else:
            return nil

# proc getUnserializer*(alias: string): Unserializer = return typeCache[alias]

# when defined(test):
#     import unittest
#     suite "hprose.io.classmanager":
#         echo "ClassManager:"
#         test "register[tuple[name: string, age: int]]('Person')":
#             register[tuple[name: string, age: int]]("Person")
#             var p:tuple[name: string, age: int] = ("Tom", 18)
#             check getAlias[type(p)]() == "Person"
#         test "register[Student]]()":
#             type
#                 Student = ref object of RootObj
#                     name: string
#                     age: int
#             register[Student]()
#             check getAlias[Student]() == "Student"
#         test "getAlias[Teacher]]()":
#             type
#                 Teacher = object of RootObj
#                     name: string
#                     age: int
#             check getAlias[Teacher]() == "Teacher"
