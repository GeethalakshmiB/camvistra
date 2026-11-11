"""Generate pybind11 bindings for the CamVistra C++ SDK classes.

The SDK public headers follow a very regular shape: a class whose public
methods return bool/int/Result and report values through non-const reference
(or pointer) out-parameters. Hand-binding the ~800 such methods is error
prone, so this script parses the headers and emits one translation unit per
header under ``native/generated/``.

Bound classes
    * every per-camera HID class in CAMSDK/include (See3CAM_*, DensiCAM, e-CAM*)
    * eCamSDK::Camera                          (CAMSDK/include/CAMSDK.h)
    * NetStreamer::NetStreamingInfo            (StreamingSDK/NetStreamSDK)
    * ShelfVistaOnvifSDK::IShelfVistaOnvifClient
    * RoutecamOnvifSDK::IRoutecamOnvifClient

Python-side conventions
    * In-parameters keep their C++ order. Enum parameters accept ``int``.
      ``TCHAR*``/``wchar_t*`` accept ``str``; ``const uint8_t*`` accepts
      ``bytes``; ``const Struct&`` accepts a ``dict`` keyed by field name.
    * Out-parameters (``T&`` / ``T*``) become trailing optional arguments
      (initial value, for in/out semantics) and are returned:
      ``ok, value = cam.getBrightness()``. Methods without out-parameters
      return the C++ return value directly (``Result`` -> ``int``).
    * Structs are converted to ``dict`` (nested structs to nested dicts,
      arrays/lists to ``list``, ``char[N]`` to ``str``). They are not
      registered as pybind11 types, which keeps the translation units
      independent of each other.
    * The GIL is released around every SDK call.

A handful of methods whose signatures cannot be expressed this way
(frames, callbacks, raw ``char*`` buffers, window handles) are bound by the
hand-written snippets in ``CUSTOM`` below.

Usage:  python tools/gen_camera_bindings.py [--platform all|win32|linux]

By default the headers are parsed once per platform and the results are
merged: code common to both is written once, platform-only methods sit in
``#ifdef _WIN32`` blocks, so the same generated files build on Windows and
Linux.
"""

from __future__ import annotations

import argparse
import difflib
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT.parent
OUT_DIR = ROOT / "native" / "generated"

SCALARS = {
    "bool", "char", "signed char", "unsigned char", "short", "unsigned short",
    "int", "unsigned", "unsigned int", "long", "unsigned long", "long long",
    "unsigned long long", "float", "double", "size_t", "uint", "BYTE", "UINT",
    "int8_t", "int16_t", "int32_t", "int64_t", "LONG", "INT", "DWORD",
    "uint8_t", "uint16_t", "uint32_t", "uint64_t", "UINT8", "UINT16", "UINT32",
}
STRINGS = {"std::string", "string"}
WIDE_STRINGS = {"TCHAR", "wchar_t", "WCHAR"}


@dataclass
class Target:
    """One generated translation unit."""
    out: str                       # output file stem
    include: str                   # header to #include
    headers: list[Path]            # headers parsed for classes and structs
    classes: list[str] | None      # class names to bind (None = all found)
    namespace: str                 # "using namespace ..." for the TU
    factory: str | None = None     # factory function returning unique_ptr
    abstract: bool = False         # no py::init
    type_headers: list[Path] = field(default_factory=list)  # parsed for structs/enums only


CAMSDK_INC = SOURCE / "CAMSDK" / "include"


def targets() -> list[Target]:
    out: list[Target] = []
    camera_headers = sorted({h for g in ("See3CAM_*.h", "DensiCAM.h", "E-cam*.h", "e-CAM*.h")
                             for h in CAMSDK_INC.glob(g)})
    for h in camera_headers:
        # Each camera class implements an interface I<header> that holds the
        # public enums and result structs; the interface itself is not bound.
        iface = h.with_name("I" + h.name)
        out.append(Target(re.sub(r"\W", "_", h.stem), h.name, [h], None, "eCamSDK",
                          type_headers=[iface] if iface.exists() else []))
    out.append(Target("Camera", "CAMSDK.h",
                      [CAMSDK_INC / "CAMSDK.h", CAMSDK_INC / "CamSDK_enums.h", CAMSDK_INC / "CAMSDK_types.h"],
                      ["Camera"], "eCamSDK"))
    ns = SOURCE / "StreamingSDK" / "NetStreamSDK"
    out.append(Target("NetStreamingInfo", "INetStream.h",
                      [ns / "INetStream.h", ns / "NetStreamEnums.h"],
                      ["NetStreamingInfo"], "NetStreamer", "NetStreamingInfoInstance", True))
    sv = SOURCE / "OnvifSDK" / "ShelfVistaSDK"
    out.append(Target("ShelfVistaOnvif", "ShelfVista.h",
                      [sv / "IShelfVistaOnvif.h", sv / "ShelfVista_Enums.h"],
                      ["IShelfVistaOnvifClient"], "ShelfVistaOnvifSDK", "getShelfVistaOnvifInstance", True))
    rc = SOURCE / "OnvifSDK" / "RoutecamOnvifSDK"
    out.append(Target("RoutecamOnvif", "Routecam.h",
                      [rc / "IRoutecamOnvif.h", rc / "Routecam_Enums.h"],
                      ["IRoutecamOnvifClient"], "RoutecamOnvifSDK", "getRoutecamOnvifInstance", True))
    return out


# Hand-written bindings: (class, method) -> C++ statement(s) using `c`/`Self`.
_GET_FRAME = """    c.def("GetFrame", [](Self& self, Frame& frame) {
        Result r{};
        { py::gil_scoped_release nogil; r = self.GetFrame(&frame); }
        return static_cast<int>(r);
    }, py::arg("frame"));
"""
_REC_CB = """    c.def("SetRecordingStartedCallback", [](Self& self, std::function<void(bool)> cb) {
        self.SetRecordingStartedCallback(std::move(cb));
    }, py::arg("callback"));
"""
_CHAR_INIT = """    c.def("initialize", [](Self& self, const std::string& ip) {
        std::vector<char> buf(ip.begin(), ip.end());
        buf.push_back('\\0');
        Result r{};
        { py::gil_scoped_release nogil; r = self.initialize(buf.data()); }
        return static_cast<int>(r);
    }, py::arg("ipAddress"));
"""
CUSTOM: dict[tuple[str, str], str] = {
    ("Camera", "GetFrame"): _GET_FRAME,
    ("Camera", "SetRecordingStartedCallback"): _REC_CB,
    ("Camera", "SetWindowHandle"): """    c.def("SetWindowHandle", [](Self& self, std::uintptr_t handle) {
        Result r{};
        { py::gil_scoped_release nogil; r = self.SetWindowHandle(reinterpret_cast<HANDLE>(handle)); }
        return static_cast<int>(r);
    }, py::arg("handle"));
""",
    ("NetStreamingInfo", "GetFrame"): _GET_FRAME,
    ("NetStreamingInfo", "SetRecordingStartedCallback"): _REC_CB,
    ("NetStreamingInfo", "registerStateCallback"): """    c.def("registerStateCallback", [](Self& self, std::function<int(int)> cb) {
        FpDeviceStatusCB wrapped = [cb](DeviceState* state) -> int {
            return cb(state != nullptr ? static_cast<int>(*state) : -1);
        };
        Result r{};
        { py::gil_scoped_release nogil; r = self.registerStateCallback(wrapped); }
        return static_cast<int>(r);
    }, py::arg("callback"));
""",
    ("DensiCAM", "setHidEventCallback"): """    c.def("setHidEventCallback", [](Self& self, std::function<void(int)> cb) {
        // Invoked from the SDK's HID read thread; pybind11 acquires the GIL.
        if (!cb) { self.setHidEventCallback(nullptr); return; }
        self.setHidEventCallback([cb](HidEventType event) { cb(static_cast<int>(event)); });
    }, py::arg("callback"));
""",
    ("IShelfVistaOnvifClient", "initialize"): _CHAR_INIT,
    ("IShelfVistaOnvifClient", "getRTSPStreamURL"): """    c.def("getRTSPStreamURL", [](Self& self) {
        std::vector<char> buf(2048, '\\0');
        Result r{};
        { py::gil_scoped_release nogil; r = self.getRTSPStreamURL(buf.data()); }
        buf.back() = '\\0';
        return py::make_tuple(static_cast<int>(r), std::string(buf.data()));
    });
""",
    ("IRoutecamOnvifClient", "initialize"): _CHAR_INIT,
}

# Classes whose destructor joins an SDK thread that invokes a Python callback;
# they are held with ts::NoGilDelete so destruction does not deadlock on the GIL.
THREADED_DESTRUCTOR = {"DensiCAM"}

CUSTOM_INIT = {
    "Camera": """    c.def(py::init([](int method) { return std::make_unique<Self>(static_cast<Method>(method)); }),
          py::arg("method") = static_cast<int>(CamMediaFoundation));
""",
}


# --------------------------------------------------------------------------
# Minimal preprocessing
# --------------------------------------------------------------------------

def strip_comments(text: str) -> str:
    text = re.sub(r"/\*.*?\*/", " ", text, flags=re.S)
    return re.sub(r"//[^\n]*", "", text)


def preprocess(text: str, platform: str) -> str:
    """Evaluate platform #if blocks; drop every other directive line."""
    defined = {"_WIN32", "_MSC_VER"} if platform == "win32" else {"__linux__"}
    known = {"_WIN32", "__linux__", "_MSC_VER"}
    out: list[str] = []
    stack: list[list[bool]] = []  # [branch_taken, active]

    def active() -> bool:
        return all(s[1] for s in stack)

    def evaluate(cond: str) -> bool:
        names = re.findall(r"defined\s*\(?\s*(\w+)\s*\)?", cond)
        if not names or not all(n in known for n in names):
            return cond.strip() != "0"
        expr = re.sub(r"defined\s*\(?\s*(\w+)\s*\)?",
                      lambda m: " True " if m.group(1) in defined else " False ", cond)
        expr = expr.replace("&&", " and ").replace("||", " or ").replace("!", " not ")
        try:
            return bool(eval(expr, {"__builtins__": {}}))  # noqa: S307 - trusted SDK headers
        except Exception:
            return True

    for line in text.splitlines():
        s = line.strip()
        m = re.match(r"#\s*(ifdef|ifndef|if|elif|else|endif)\b(.*)", s)
        if m:
            kind, rest = m.group(1), m.group(2).strip()
            if kind in ("ifdef", "ifndef"):
                name = rest.split()[0] if rest else ""
                val = ((name in defined) == (kind == "ifdef")) if name in known else kind == "ifndef"
                stack.append([val, val])
            elif kind == "if":
                val = evaluate(rest)
                stack.append([val, val])
            elif kind == "elif" and stack:
                val = (not stack[-1][0]) and evaluate(rest)
                stack[-1] = [stack[-1][0] or val, val]
            elif kind == "else" and stack:
                stack[-1] = [True, not stack[-1][0]]
            elif kind == "endif" and stack:
                stack.pop()
            continue
        if s.startswith("#"):
            continue
        if active():
            out.append(line)
    return "\n".join(out)


def matching_brace(text: str, open_idx: int) -> int:
    depth = 0
    for i in range(open_idx, len(text)):
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
            if depth == 0:
                return i
    raise ValueError("unbalanced braces")


def split_top(s: str, sep: str = ",") -> list[str]:
    out, depth, cur = [], 0, []
    for ch in s:
        if ch in "<([":
            depth += 1
        elif ch in ">)]":
            depth -= 1
        if ch == sep and depth == 0:
            out.append("".join(cur))
            cur = []
        else:
            cur.append(ch)
    out.append("".join(cur))
    return [p.strip() for p in out if p.strip()]


# --------------------------------------------------------------------------
# Model and parsing
# --------------------------------------------------------------------------

@dataclass
class Param:
    raw: str
    base: str
    name: str
    is_const: bool
    is_ref: bool
    is_ptr: bool
    default: str | None


@dataclass
class Method:
    name: str
    ret: str
    params: list[Param]


@dataclass
class ClassDecl:
    name: str
    methods: list[Method] = field(default_factory=list)
    skipped: list[str] = field(default_factory=list)


@dataclass
class Struct:
    name: str
    fields: list[tuple[str, str]]  # (type, name)


def parse_structs(text: str) -> list[Struct]:
    structs: list[Struct] = []
    for m in re.finditer(r"\b(typedef\s+)?struct\s+(\w+)?\s*\{", text):
        start = m.end() - 1
        end = matching_brace(text, start)
        name = m.group(2)
        if m.group(1):
            tail = re.match(r"\s*(\w+)\s*;", text[end + 1:])
            if tail:
                name = tail.group(1)
        if name:
            structs.append(Struct(name, parse_fields(text[start + 1:end])))
    return structs


def parse_fields(body: str) -> list[tuple[str, str]]:
    fields: list[tuple[str, str]] = []
    while True:  # drop brace initialisers and nested bodies
        new = re.sub(r"\{[^{}]*\}", "", body)
        if new == body:
            break
        body = new
    for decl in body.split(";"):
        decl = " ".join(decl.split())
        if not decl or "(" in decl or decl.startswith(("public:", "private:", "enum", "using", "typedef")):
            continue
        decl = re.sub(r"^(public|private|protected)\s*:\s*", "", decl)
        parts = split_top(decl)
        parts = [re.sub(r"\[[^\]]*\]", "", re.sub(r"=.*$", "", p)).strip() for p in parts]
        first = parts[0].replace("*", " * ").replace("&", " & ").split()
        if len(first) < 2:
            continue
        ftype = " ".join(first[:-1])
        fields.append((ftype, first[-1]))
        fields.extend((ftype, p.split()[-1].lstrip("*&")) for p in parts[1:] if p)
    return fields


def parse_param(raw: str) -> Param | None:
    raw = " ".join(raw.split())
    if not raw or raw == "void":
        return None
    default = None
    if "=" in raw:
        raw, default = (s.strip() for s in raw.split("=", 1))
    raw = re.sub(r"\bstruct\s+", "", raw)
    is_const = bool(re.search(r"\bconst\b", raw))
    is_ref = "&" in raw
    is_ptr = "*" in raw
    cleaned = re.sub(r"\bconst\b", "", raw).replace("&", " ").replace("*", " ")
    toks = cleaned.split()
    if len(toks) == 1:
        base, name = toks[0], ""
    else:
        base, name = " ".join(toks[:-1]), toks[-1]
    if base.startswith("std::") is False and base in ("list", "vector", "map"):
        base = "std::" + base
    return Param(raw, base, name, is_const, is_ref, is_ptr, default)


def parse_classes(text: str) -> list[ClassDecl]:
    classes = []
    for m in re.finditer(r"\bclass\s+(?:[A-Z_]+\s+)?(\w+)\s*(?:final\s*)?(?::[^{;]*)?\{", text):
        name = m.group(1)
        start = m.end() - 1
        end = matching_brace(text, start)
        cls = ClassDecl(name)
        flat, depth = [], 0
        for ch in text[start + 1:end]:
            if ch == "{":
                depth += 1
                if depth == 1:
                    flat.append(";")
                continue
            if ch == "}":
                depth -= 1
                continue
            if depth == 0:
                flat.append(ch)
        access = "private"
        for stmt in "".join(flat).split(";"):
            stmt = " ".join(stmt.split())
            while True:
                am = re.match(r"(public|private|protected)\s*:\s*(.*)", stmt)
                if not am:
                    break
                access, stmt = am.group(1), am.group(2)
            if access != "public" or "(" not in stmt:
                continue
            if stmt.startswith(("__pragma", "friend", "static", "template", "typedef", "using")):
                continue
            mm = re.match(r"(?:virtual\s+|inline\s+|explicit\s+)*(.*?)\b(~?\w+)\s*\((.*)\)\s*(?:const)?\s*(?:override)?\s*(?:=\s*\w+)?$", stmt)
            if not mm:
                cls.skipped.append(f"unparsed: {stmt}")
                continue
            ret, mname, params = mm.group(1).strip(), mm.group(2), mm.group(3)
            if mname in (name, "~" + name) or not ret or mname.startswith("operator"):
                continue
            plist = [p for p in (parse_param(x) for x in split_top(params)) if p]
            cls.methods.append(Method(mname, ret, plist))
        classes.append(cls)
    return classes


# --------------------------------------------------------------------------
# Code generation
# --------------------------------------------------------------------------

class Unsupported(Exception):
    pass


def classify(p: Param, structs: set[str]) -> str:
    base = p.base
    if base in WIDE_STRINGS and p.is_ptr:
        return "wstr"
    if base == "char" and p.is_ptr and p.is_const:
        return "cstr"
    if base in ("uint8_t", "unsigned char", "BYTE") and p.is_ptr and p.is_const:
        return "bytes"
    if "Callback" in base or "function" in base or base.endswith("CB"):
        raise Unsupported(f"callback parameter '{p.raw}'")
    if p.is_ptr and base in ("char", "unsigned char", "uint8_t", "void", "HANDLE"):
        raise Unsupported(f"raw buffer parameter '{p.raw}'")
    if base == "HANDLE" or base == "HWND":
        raise Unsupported(f"handle parameter '{p.raw}'")
    if base in STRINGS:
        return "str_in" if (p.is_const or not p.is_ref) else "out"
    if p.is_ref or p.is_ptr:
        if p.is_const:
            if base in SCALARS:
                return "scalar"
            return "struct_in"
        return "out"
    if base in structs or base.startswith("std::"):
        return "struct_in"
    if base in SCALARS:
        return "scalar"
    return "enum"


def gen_method(m: Method, structs: set[str]) -> str:
    kinds = [classify(p, structs) for p in m.params]
    args, req, opt, outs_args = ["Self& self"], [], [], []
    pre, call, outs = [], [], []
    for i, (p, kind) in enumerate(zip(m.params, kinds)):
        pname = p.name or f"arg{i}"
        var = f"a{i}"
        if kind == "scalar":
            args.append(f"{p.base} {var}")
            call.append(var)
        elif kind == "enum":
            args.append(f"long long {var}")
            call.append(f"static_cast<{p.base}>({var})")
        elif kind == "str_in":
            args.append(f"const std::string& {var}")
            call.append(var)
        elif kind == "cstr":
            args.append(f"py::object {var}")
            pre.append(f"const bool {var}_null = {var}.is_none();")
            pre.append(f"const std::string {var}_s = {var}_null ? std::string() : {var}.cast<std::string>();")
            call.append(f"({var}_null ? nullptr : {var}_s.c_str())")
        elif kind == "wstr":
            args.append(f"const std::wstring& {var}")
            pre.append(f"std::wstring {var}_w = {var};")
            call.append(f"const_cast<{p.base}*>(reinterpret_cast<const {p.base}*>({var}_w.c_str()))")
        elif kind == "bytes":
            args.append(f"py::object {var}")
            pre.append(f"const bool {var}_null = {var}.is_none();")
            pre.append(f"const std::string {var}_b = {var}_null ? std::string() : {var}.cast<std::string>();")
            call.append(f"({var}_null ? nullptr : reinterpret_cast<const {p.base}*>({var}_b.data()))")
        elif kind == "struct_in":
            args.append(f"py::object {var}")
            pre.append(f"{p.base} {var}_v{{}}; if (!{var}.is_none()) ts::from_py({var}, {var}_v);")
            call.append(f"&{var}_v" if p.is_ptr else f"{var}_v")
        elif kind == "out":
            args.append(f"py::object {var}")
            ctype = "std::string" if p.base in STRINGS else p.base
            pre.append(f"{ctype} {var}_v{{}}; if (!{var}.is_none()) ts::from_py({var}, {var}_v);")
            call.append(f"&{var}_v" if p.is_ptr else f"{var}_v")
            outs.append(f"ts::to_py({var}_v)")
        if kind == "out":
            outs_args.append(f'py::arg("{pname}") = py::none()')
        elif p.default is not None:
            d = p.default
            if kind in ("cstr", "bytes", "struct_in") or d in ("nullptr", "NULL"):
                d = "py::none()"
            opt.append(f'py::arg("{pname}") = {d}')
        else:
            if opt:
                raise Unsupported("required parameter after defaulted one")
            req.append(f'py::arg("{pname}")')

    ret = re.sub(r"\b(inline|virtual|static)\b", "", m.ret).strip()
    body = ["        " + s for s in pre]
    call_expr = f"self.{m.name}({', '.join(call)})"
    if ret == "void":
        body.append(f"        {{ py::gil_scoped_release nogil; {call_expr}; }}")
        result = "py::none()"
    else:
        body.append(f"        {ret} r{{}};")
        body.append(f"        {{ py::gil_scoped_release nogil; r = {call_expr}; }}")
        result = "ts::to_py(r)"
    if outs:
        body.append(f"        return py::object(py::make_tuple({result}, {', '.join(outs)}));")
    else:
        body.append(f"        return py::object({result});")
    pyargs = req + opt + outs_args
    extra = (", " + ", ".join(pyargs)) if pyargs else ""
    return (f'    c.def("{m.name}", []({", ".join(args)}) {{\n'
            + "\n".join(body) + f"\n    }}{extra});\n")


def reachable_structs(methods: list[Method], structs: dict[str, Struct]) -> list[str]:
    todo = set()
    for m in methods:
        for p in m.params:
            todo.update(re.findall(r"\w+", p.base))
        todo.update(re.findall(r"\w+", m.ret))
    seen: set[str] = set()
    while todo:
        t = todo.pop()
        if t in structs and t not in seen:
            seen.add(t)
            for ftype, _ in structs[t].fields:
                todo.update(re.findall(r"\w+", ftype))
    return [s for s in structs if s in seen]  # keep header order


# Public methods inherited from eCamSDK::UvcExt (platform/<os>/UvcExt.h) that
# the camera Models call. The remaining UvcExt methods take COM/V4L2 pointers.
UVCEXT_METHODS = {"initUVCExtension", "initialize"}


def uvcext_methods(platform: str) -> list[Method]:
    plat = "windows" if platform == "win32" else "linux"
    header = CAMSDK_INC / "platform" / plat / "UvcExt.h"
    text = preprocess(strip_comments(header.read_text(encoding="utf-8", errors="replace")), platform)
    for cls in parse_classes(text):
        if cls.name == "UvcExt":
            return [m for m in cls.methods if m.name in UVCEXT_METHODS]
    return []


def read_headers(headers: list[Path], platform: str) -> str:
    return "\n".join(preprocess(strip_comments(h.read_text(encoding="utf-8", errors="replace")), platform)
                     for h in headers)


def generate(target: Target, platform: str) -> tuple[list[str], list[ClassDecl]]:
    """Return the translation unit as a list of chunks (one per method/struct)."""
    text = read_headers(target.headers, platform)
    type_text = read_headers(target.type_headers, platform) + "\n" + text
    structs = {s.name: s for s in parse_structs(type_text)}
    classes = [c for c in parse_classes(text) if c.methods
               and (target.classes is None or c.name in target.classes)]
    for c in classes:
        if re.search(rf"\bclass\s+(?:[A-Z_]+\s+)?{c.name}\s*:[^{{;]*\bpublic\s+UvcExt\b", text):
            own = {m.name for m in c.methods}
            c.methods += [m for m in uvcext_methods(platform) if m.name not in own]
    bound_methods: list[Method] = []
    body: list[str] = []
    for c in classes:
        body.append(f"void bind_{c.name}(py::module_& m) {{")
        body.append(f"    using Self = {c.name};")
        if target.factory:
            body.append(f'    py::class_<Self, std::unique_ptr<Self>> c(m, "{c.name}");')
            body.append(f'    m.def("{target.factory}", &{target.factory}, '
                        "py::call_guard<py::gil_scoped_release>());")
        elif c.name in THREADED_DESTRUCTOR:
            body.append(f'    py::class_<Self, std::unique_ptr<Self, ts::NoGilDelete<Self>>> '
                        f'c(m, "{c.name}");')
        else:
            body.append(f'    py::class_<Self> c(m, "{c.name}");')
        if not target.abstract:
            body.append(CUSTOM_INIT.get(c.name, "    c.def(py::init<>());\n").rstrip("\n"))
        done: set[str] = set()
        for meth in c.methods:
            key = (c.name, meth.name)
            if key in CUSTOM:
                if meth.name not in done:
                    body.append(CUSTOM[key].rstrip("\n"))
                    done.add(meth.name)
                continue
            try:
                body.append(gen_method(meth, set(structs)).rstrip("\n"))
                bound_methods.append(meth)
            except Unsupported as exc:
                c.skipped.append(f"{meth.name}: {exc}")
                body.append(f"    // SKIPPED {meth.name}: {exc}")
        body.append("}")
        body.append("")

    used = reachable_structs(bound_methods, structs)
    head = [
        "// GENERATED by tools/gen_camera_bindings.py - DO NOT EDIT.",
        "// Sources: " + ", ".join(h.relative_to(SOURCE).as_posix() for h in target.headers),
        '#include "../common.h"',
        f'#include "{target.include}"',
        "",
        f"using namespace {target.namespace};",
        "",
        "namespace ts {",
    ]
    for s in used:
        head.append("\n".join([
            f"template <> struct Conv<{s}> {{",
            f"    static py::object to(const {s}& v);",
            f"    static void from(py::handle h, {s}& v);",
            "};"]))
    for s in used:
        head.append("\n".join([
            f"inline py::object Conv<{s}>::to(const {s}& v) {{",
            "    py::dict d;",
            *(f'    d["{f}"] = to_py(v.{f});' for _, f in structs[s].fields),
            "    return std::move(d);",
            "}",
            f"inline void Conv<{s}>::from(py::handle h, {s}& v) {{",
            "    auto d = py::reinterpret_borrow<py::dict>(h);",
            *(f'    if (d.contains("{f}")) from_py(d["{f}"], v.{f});' for _, f in structs[s].fields),
            "}"]))
    head += ["}  // namespace ts", ""]
    return head + body, classes


PLATFORMS = ("win32", "linux")


def merge_platforms(win: list[str], lin: list[str]) -> list[str]:
    """Merge the Windows and Linux chunk lists into one translation unit.

    Chunks common to both are emitted once; the rest are wrapped in
    ``#ifdef _WIN32`` / ``#else`` so the same file builds on either OS.
    """
    out: list[str] = []
    sm = difflib.SequenceMatcher(a=win, b=lin, autojunk=False)
    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        if tag == "equal":
            out += win[i1:i2]
        elif tag == "delete":
            out += ["#ifdef _WIN32", *win[i1:i2], "#endif"]
        elif tag == "insert":
            out += ["#ifndef _WIN32", *lin[j1:j2], "#endif"]
        else:
            out += ["#ifdef _WIN32", *win[i1:i2], "#else", *lin[j1:j2], "#endif"]
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--platform", choices=("all", *PLATFORMS), default="all",
                    help="'all' (default) writes files that build on both platforms")
    args = ap.parse_args()
    platforms = PLATFORMS if args.platform == "all" else (args.platform,)

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for old in OUT_DIR.glob("bind_*.cpp"):
        old.unlink()
    per_platform: dict[str, list[ClassDecl]] = {p: [] for p in platforms}
    registry: dict[str, list[str]] = {p: [] for p in platforms}
    for t in targets():
        chunks: dict[str, list[str]] = {}
        for p in platforms:
            code, classes = generate(t, p)
            if classes:
                chunks[p] = code
                per_platform[p].extend(classes)
                registry[p] += [c.name for c in classes]
        if not chunks:
            print(f"warning: no class bound for {t.out}", file=sys.stderr)
            continue
        if len(platforms) == 1:
            merged = chunks[platforms[0]]
        elif len(chunks) == 1:
            (p, code), = chunks.items()
            guard = "#ifdef _WIN32" if p == "win32" else "#ifndef _WIN32"
            merged = [guard, *code, "#endif"]
        else:
            merged = merge_platforms(chunks["win32"], chunks["linux"])
        (OUT_DIR / f"bind_{t.out}.cpp").write_text("\n".join(merged) + "\n", encoding="utf-8")

    def reg_lines(names: list[str]) -> tuple[list[str], list[str]]:
        return ([f"void bind_{n}(py::module_& m);" for n in names],
                [f"    bind_{n}(m);" for n in names])

    if len(platforms) == 1:
        decls, calls = reg_lines(registry[platforms[0]])
    else:
        dw, cw = reg_lines(registry["win32"])
        dl, cl = reg_lines(registry["linux"])
        decls, calls = merge_platforms(dw, dl), merge_platforms(cw, cl)
    reg = ["// GENERATED by tools/gen_camera_bindings.py - DO NOT EDIT.",
           '#include "../common.h"', ""]
    reg += decls + ["", "void bind_generated(py::module_& m) {"] + calls + ["}", ""]
    (OUT_DIR / "registry.cpp").write_text("\n".join(reg), encoding="utf-8")

    for p in platforms:
        all_classes = per_platform[p]
        total = sum(len(c.methods) for c in all_classes)
        print(f"{p}: generated {len(all_classes)} classes, {total} methods -> {OUT_DIR.relative_to(ROOT)}")
        for c in all_classes:
            for sk in c.skipped:
                print(f"  {p}: skipped {c.name}.{sk}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
