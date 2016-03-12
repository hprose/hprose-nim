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
# hprose/io/reader.nim                                     #
#                                                          #
# hprose reader for Nim                                    #
#                                                          #
# LastModified: Mar 12, 2016                               #
# Author: Ma Bingyao <andot@hprose.com>                    #
#                                                          #
############################################################

import strutils, tables, sets, lists, queues, intsets, critbits, strtabs, streams, times
import tags

type
    ReaderRefer = ref object of RootObj

    FakeReaderRefer = ref object of ReaderRefer

    RealReaderRefer = ref object of ReaderRefer
        stream: Stream
        references: seq[pointer]

method setRef(r: ReaderRefer, p: pointer) {.base, inline.} = discard
method readRef(r: ReaderRefer, i: int): pointer {.base, inline.} =
    raise newException(IOError, "Unexcepted serialize tag '" & tag_ref & "' in stream")
method resetRef(r: ReaderRefer) {.base, inline.} = discard

proc newFakeReaderRefer(): FakeReaderRefer = new result

method setRef(r: RealReaderRefer, p: pointer) {.inline.} =
    r.references.add p
method readRef(r: RealReaderRefer, i: int): pointer {.inline.} =
    return r.references[i]
method resetRef(r: RealReaderRefer) {.inline.} =
    r.references = @[]

proc newRealReaderRefer(): RealReaderRefer =
    new result
    result.resetRef

type
    RawReader = ref object of RootObj
        stream*: Stream

proc unexpectedTag*(tag: char, expectTags: string = ""): ref Exception =
    if tag.ord != 0 and expectTags.len != 0:
        return newException(IOError, "Tags '" & expectTags & "' expected, but '" & tag & "' found in stream")
    elif tag.ord != 0:
        return newException(IOError, "Unexpected serialize tag '" & tag & "' in stream")
    else:
        return newException(IOError, "No byte found in stream")

proc stoi(s: string): int = return if s.len == 0: 0 else: s.parseInt

proc readUntil*(stream: Stream, tag: char): string =
    result = ""
    var c: char
    while stream.readData(c.addr, 1) == 1:
        if c != tag:
            result.add(c)
        else:
            break

proc readUntil*(stream: Stream, tags: set[char]): string =
    result = ""
    var c: char
    while stream.readData(c.addr, 1) == 1:
        if c notin tags:
            result.add(c)
        else:
            break

proc readBytes*(stream: Stream, tag: char): string =
    result = ""
    var c: char
    while stream.readData(c.addr, 1) == 1:
        result.add(c)
        if c == tag: break

proc readBytes*(stream: Stream, tags: set[char]): string =
    result = ""
    var c: char
    while stream.readData(c.addr, 1) == 1:
        result.add(c)
        if c in tags: break

proc read*(s: Stream): char =
    if s.readData(addr(result), 1) != 1:
        echo result
        raise newException(IOError, "cannot read from stream")

proc readUTF8Char*(stream: Stream): string =
    result = ""
    var c = stream.read
    case c.ord shr 4:
    of 0..7:
        result.add c
    of 12, 13:
        result.add c
        result.add stream.read
    of 14:
        result.add c
        result.add stream.read
        result.add stream.read
    else:
        raise newException(IOError, "bad utf-8 encoding");

proc readString*(stream: Stream, len: int): string =
    result = ""
    var i = 0
    while i < len:
        var c = stream.read
        case c.ord shr 4:
        of 0..7:
            result.add c
        of 12, 13:
            result.add c
            result.add stream.read
        of 14:
            result.add c
            result.add stream.read
            result.add stream.read
        of 15:
            result.add c
            result.add stream.read
            result.add stream.read
            result.add stream.read
            inc i
        else:
            raise newException(IOError, "bad utf-8 encoding");
        inc i

proc readNumberRaw(reader: RawReader, stream: Stream) =
    stream.write reader.stream.readBytes tag_semicolon

proc readDateTimeRaw(reader: RawReader, stream: Stream) =
    const tags = {tag_semicolon, tag_utc}
    stream.write reader.stream.readBytes tags

proc readUTF8CharRaw(reader: RawReader, stream: Stream) =
    stream.write reader.stream.readUTF8Char

proc readBytesRaw(reader: RawReader, stream: Stream) =
    let len = reader.stream.readUntil tag_quote
    stream.write len
    stream.write tag_quote
    stream.write reader.stream.readStr len.stoi
    stream.write tag_quote
    discard reader.stream.read

proc readStringRaw(reader: RawReader, stream: Stream) =
    let len = reader.stream.readUntil tag_quote
    stream.write len
    stream.write tag_quote
    stream.write reader.stream.readString len.stoi
    stream.write tag_quote
    discard reader.stream.read

proc readGuidRaw(reader: RawReader, stream: Stream) =
    stream.write reader.stream.readStr 38

proc readRaw*(reader: RawReader, stream: Stream, tag: char)

proc readComplexRaw(reader: RawReader, stream: Stream) =
    stream.write reader.stream.readBytes tag_openbrace
    var c = reader.stream.read
    while c != tag_closebrace:
        reader.readRaw stream, c
        c = reader.stream.read
    stream.write c

proc readRaw*(reader: RawReader): StringStream {.inline.} =
    result = newStringStream()
    readRaw(reader, result, reader.stream.read)

proc readRaw*(reader: RawReader, stream: Stream) {.inline.} =
    readRaw(reader, stream, reader.stream.read)

proc readRaw*(reader: RawReader, stream: Stream, tag: char) =
    stream.write tag
    case tag:
    of '0'..'9', tag_null, tag_empty, tag_true, tag_false, tag_nan: discard
    of tag_infinity: stream.write reader.stream.read
    of tag_integer, tag_long, tag_double, tag_ref: reader.readNumberRaw stream
    of tag_date, tag_time: reader.readDateTimeRaw stream
    of tag_utf8char: reader.readUTF8CharRaw stream
    of tag_bytes: reader.readBytesRaw stream
    of tag_string: reader.readStringRaw stream
    of tag_guid: reader.readGuidRaw stream
    of tag_list, tag_map, tag_object: reader.readComplexRaw stream
    of tag_class:
        reader.readComplexRaw stream
        reader.readRaw stream
    of tag_error: reader.readRaw stream
    else:
        raise unexpectedTag(tag)

proc newRawReader*(stream: Stream): RawReader =
    new result
    result.stream = stream

type
    Reader* = ref object of RawReader
        refer: ReaderRefer
        classref: seq[tuple[name: string, fields: seq[string]]]

proc newReader*(stream: Stream, simple: bool = false): Reader =
    new result
    result.stream = stream
    result.refer = if simple: newFakeReaderRefer() else: newRealReaderRefer()


proc setRef*(reader:Reader, p: pointer) = discard

proc unserialize*[T](reader: Reader): T =
    when T is SomeInteger:
        return 0
    when T is ref|ptr:
        return nil

when defined(test):
    import unittest
    suite "hprose.io.reader":
        echo "RawReader:"
        test "readRaw":
            var reader = newRawReader(newStringStream("ne09i10;tfNI+I-l100;d3.14;D19801201ZD19801201T221323.123;"))
            check reader.readRaw.data == "n"
            check reader.readRaw.data == "e"
            check reader.readRaw.data == "0"
            check reader.readRaw.data == "9"
            check reader.readRaw.data == "i10;"
            check reader.readRaw.data == "t"
            check reader.readRaw.data == "f"
            check reader.readRaw.data == "N"
            check reader.readRaw.data == "I+"
            check reader.readRaw.data == "I-"
            check reader.readRaw.data == "l100;"
            check reader.readRaw.data == "d3.14;"
            check reader.readRaw.data == "D19801201Z"
            check reader.readRaw.data == "D19801201T221323.123;"
            reader = newRawReader(newStringStream("T120012Zs11\"hello world\"b11\"hello world\""))
            check reader.readRaw.data == "T120012Z"
            check reader.readRaw.data == "s11\"hello world\""
            check reader.readRaw.data == "b11\"hello world\""
            reader = newRawReader(newStringStream("g{AFA7F4B1-A64D-46FA-886F-ED7FBCE569B6}a{}a10{0123456789}"))
            check reader.readRaw.data == "g{AFA7F4B1-A64D-46FA-886F-ED7FBCE569B6}"
            check reader.readRaw.data == "a{}"
            check reader.readRaw.data == "a10{0123456789}"
            reader = newRawReader(newStringStream("a7{s3\"Mon\"s3\"Tue\"s3\"Wed\"s3\"Thu\"s3\"Fri\"s3\"Sat\"s3\"Sun\"}"))
            check reader.readRaw.data == "a7{s3\"Mon\"s3\"Tue\"s3\"Wed\"s3\"Thu\"s3\"Fri\"s3\"Sat\"s3\"Sun\"}"
            reader = newRawReader(newStringStream("m2{s4\"name\"s5\"Tommy\"s3\"age\"i24;}"))
            check reader.readRaw.data == "m2{s4\"name\"s5\"Tommy\"s3\"age\"i24;}"
            reader = newRawReader(newStringStream("a2{c6\"Person\"2{s4\"name\"s3\"age\"}o0{s5\"Tommy\"i24;}o0{s5\"Jerry\"i19;}}"))
            check reader.readRaw.data == "a2{c6\"Person\"2{s4\"name\"s3\"age\"}o0{s5\"Tommy\"i24;}o0{s5\"Jerry\"i19;}}"
            reader = newRawReader(newStringStream("a2{m2{s4\"name\"s5\"Tommy\"s3\"age\"i24;}m2{r2;s5\"Jerry\"r4;i18;}}"))
            check reader.readRaw.data == "a2{m2{s4\"name\"s5\"Tommy\"s3\"age\"i24;}m2{r2;s5\"Jerry\"r4;i18;}}"
