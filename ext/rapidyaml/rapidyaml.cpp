// Rice 4.x binding layer.
// Converts ryml tree nodes to Ruby objects; no Ruby concerns in core logic.

#include <rice/rice.hpp>
#include <rice/stl.hpp>

#define RYML_SINGLE_HDR_DEFINE_NOW
#include "ryml_all.hpp"

#include <limits>
#include <stdexcept>
#include <string>

using Rice::Array;
using Rice::Hash;
using Rice::Module;
using Rice::Object;
using Rice::String;

// --------------------------------------------------------------------------
// ryml error callbacks — throw C++ exceptions instead of calling abort()
// --------------------------------------------------------------------------

struct RymlParseError : public std::runtime_error {
    using std::runtime_error::runtime_error;
};

struct RymlError : public std::runtime_error {
    using std::runtime_error::runtime_error;
};

[[noreturn]] static void throwing_error_parse(
    c4::csubstr msg, ryml::ErrorDataParse const& /*errdata*/, void* /*user_data*/)
{
    throw RymlParseError(std::string(msg.str, msg.len));
}

[[noreturn]] static void throwing_error_basic(
    c4::csubstr msg, ryml::ErrorDataBasic const& /*errdata*/, void* /*user_data*/)
{
    throw RymlError(std::string(msg.str, msg.len));
}

[[noreturn]] static void throwing_error_visit(
    c4::csubstr msg, ryml::ErrorDataVisit const& /*errdata*/, void* /*user_data*/)
{
    throw RymlError(std::string(msg.str, msg.len));
}

// Ruby exception VALUE handles — set during Init_
static VALUE rb_eRapidYAMLError       = Qnil;
static VALUE rb_eRapidYAMLSyntaxError = Qnil;

// --------------------------------------------------------------------------
// Forward declarations
// --------------------------------------------------------------------------

static Object node_to_ruby(ryml::ConstNodeRef const& node);
static Object scalar_to_ruby(c4::csubstr val, bool is_null);
static Object tagged_scalar_to_ruby(c4::csubstr tag, c4::csubstr val, bool is_null);
static Object node_val_to_ruby(ryml::ConstNodeRef const& node);
static Object node_key_to_ruby(ryml::ConstNodeRef const& child);
static Object map_to_ruby(ryml::ConstNodeRef const& node);
static Object seq_to_ruby(ryml::ConstNodeRef const& node);

// --------------------------------------------------------------------------
// Scalar coercion
// --------------------------------------------------------------------------

static Object scalar_to_ruby(c4::csubstr val, bool is_null)
{
    if (is_null || val == "~" || val == "null" || val == "Null" || val == "NULL")
        return Object(Qnil);

    if (val == "true"  || val == "True"  || val == "TRUE")  return Object(Qtrue);
    if (val == "false" || val == "False" || val == "FALSE") return Object(Qfalse);

    // YAML 1.2 float specials
    if (val == ".inf" || val == ".Inf" || val == ".INF")
        return Rice::detail::To_Ruby<double>().convert(std::numeric_limits<double>::infinity());
    if (val == "-.inf" || val == "-.Inf" || val == "-.INF")
        return Rice::detail::To_Ruby<double>().convert(-std::numeric_limits<double>::infinity());
    if (val == ".nan" || val == ".NaN" || val == ".NAN")
        return Rice::detail::To_Ruby<double>().convert(std::numeric_limits<double>::quiet_NaN());

    if (val.len == 0)
        return Rice::detail::To_Ruby<std::string>().convert(std::string{});

    std::string s(val.str, val.len);

    // Detect leading zeros: "090", "00.5", etc. are strings in YAML 1.2.
    // "0" and "-0" are fine; "0x..." goes to the hex path below.
    {
        const char *p = s.c_str();
        bool negative = (*p == '-' || *p == '+');
        const char *digits = p + (negative ? 1 : 0);
        bool leading_zero = (digits[0] == '0' && digits[1] != '\0' &&
                             digits[1] != 'x' && digits[1] != 'X' &&
                             digits[1] != '.');
        if (leading_zero)
            return Rice::detail::To_Ruby<std::string>().convert(s);
    }

    // Reject sexagesimal-style scalars (YAML 1.1 only). "20:03:20" is a plain
    // string in YAML 1.2; strtoll would parse only the leading digits and stop.
    // A colon anywhere after the optional sign means this is not a bare integer.
    {
        const char *colon_check = s.c_str() + (*s.c_str() == '-' || *s.c_str() == '+' ? 1 : 0);
        if (std::strchr(colon_check, ':') != nullptr)
            return Rice::detail::To_Ruby<std::string>().convert(s);
    }

    // Integer?
    {
        char *end = nullptr;
        long long iv = std::strtoll(s.c_str(), &end, 10);
        if (end == s.c_str() + s.size())
            return Rice::detail::To_Ruby<long long>().convert(iv);
    }

    // Hex integer?
    if (s.size() > 2 && s[0] == '0' && (s[1] == 'x' || s[1] == 'X')) {
        char *end = nullptr;
        long long iv = std::strtoll(s.c_str(), &end, 16);
        if (end == s.c_str() + s.size())
            return Rice::detail::To_Ruby<long long>().convert(iv);
    }

    // Float?
    {
        char *end = nullptr;
        double dv = std::strtod(s.c_str(), &end);
        if (end == s.c_str() + s.size())
            return Rice::detail::To_Ruby<double>().convert(dv);
    }

    return Rice::detail::To_Ruby<std::string>().convert(s);
}

// Decode base64 (YAML !!binary). Ignores whitespace per RFC 4648.
static std::string base64_decode(c4::csubstr encoded)
{
    static const signed char tbl[256] = {
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,62,-1,-1,-1,63,
        52,53,54,55,56,57,58,59,60,61,-1,-1,-1,-2,-1,-1,
        -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14,
        15,16,17,18,19,20,21,22,23,24,25,-1,-1,-1,-1,-1,
        -1,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,
        41,42,43,44,45,46,47,48,49,50,51,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
    };
    std::string out;
    out.reserve((encoded.len * 3) / 4);
    int buf = 0, bits = 0;
    for (size_t i = 0; i < encoded.len; ++i) {
        signed char v = tbl[(unsigned char)encoded.str[i]];
        if (v == -1) continue; // whitespace
        if (v == -2) break;    // padding '='
        buf = (buf << 6) | v;
        bits += 6;
        if (bits >= 8) {
            bits -= 8;
            out += (char)((buf >> bits) & 0xFF);
        }
    }
    return out;
}

// Handle an explicit YAML tag on a scalar value.
static Object tagged_scalar_to_ruby(c4::csubstr tag, c4::csubstr val, bool is_null)
{
    std::string t(tag.str, tag.len);

    // Non-specific tag "!" — treat as string per YAML 1.2 core schema.
    // Psych disagrees (it coerces), but the test suite JSON expects strings.
    if (t == "!" || t == "<!>")
        return Rice::detail::To_Ruby<std::string>().convert(std::string(val.str, val.len));

    auto tag_is = [&](const char* a, const char* b, const char* c = nullptr, const char* d = nullptr) -> bool {
        return t == a || t == b || (c && t == c) || (d && t == d);
    };

    if (tag_is("!!str", "tag:yaml.org,2002:str", "<tag:yaml.org,2002:str>")) {
        return Rice::detail::To_Ruby<std::string>().convert(std::string(val.str, val.len));
    }

    if (tag_is("!!null", "tag:yaml.org,2002:null", "<tag:yaml.org,2002:null>")) {
        return Object(Qnil);
    }

    if (tag_is("!!bool", "tag:yaml.org,2002:bool", "<tag:yaml.org,2002:bool>")) {
        std::string v(val.str, val.len);
        if (v == "true" || v == "True" || v == "TRUE")  return Object(Qtrue);
        if (v == "false" || v == "False" || v == "FALSE") return Object(Qfalse);
        return scalar_to_ruby(val, is_null);
    }

    if (tag_is("!!int", "tag:yaml.org,2002:int", "<tag:yaml.org,2002:int>")) {
        std::string s(val.str, val.len);
        char *end = nullptr;
        long long iv = std::strtoll(s.c_str(), &end, 10);
        if (end == s.c_str() + s.size())
            return Rice::detail::To_Ruby<long long>().convert(iv);
        return scalar_to_ruby(val, is_null);
    }

    if (tag_is("!!float", "tag:yaml.org,2002:float", "<tag:yaml.org,2002:float>")) {
        std::string s(val.str, val.len);
        char *end = nullptr;
        double dv = std::strtod(s.c_str(), &end);
        if (end == s.c_str() + s.size())
            return Rice::detail::To_Ruby<double>().convert(dv);
        return scalar_to_ruby(val, is_null);
    }

    if (tag_is("!!binary", "tag:yaml.org,2002:binary", "<tag:yaml.org,2002:binary>")) {
        std::string decoded = base64_decode(val);
        VALUE rb_str = rb_str_new(decoded.data(), (long)decoded.size());
        rb_enc_associate(rb_str, rb_ascii8bit_encoding());
        return Object(rb_str);
    }

    // Unknown or unhandled tag — fall through to normal coercion.
    return scalar_to_ruby(val, is_null);
}


static Object node_val_to_ruby(ryml::ConstNodeRef const& node)
{
    bool is_null = node.type().has_any(ryml::VALNIL);
    if (node.has_val_tag())
        return tagged_scalar_to_ruby(node.val_tag(), node.val(), is_null);
    if (node.type().has_any(ryml::VAL_DQUO | ryml::VAL_SQUO))
        return Rice::detail::To_Ruby<std::string>().convert(std::string(node.val().str, node.val().len));
    return scalar_to_ruby(node.val(), is_null);
}

static Object node_key_to_ruby(ryml::ConstNodeRef const& child)
{
    bool key_null = child.type().has_any(ryml::KEYNIL);
    if (child.has_key_tag())
        return tagged_scalar_to_ruby(child.key_tag(), child.key(), key_null);
    if (child.type().has_any(ryml::KEY_DQUO | ryml::KEY_SQUO))
        return Rice::detail::To_Ruby<std::string>().convert(std::string(child.key().str, child.key().len));
    return scalar_to_ruby(child.key(), key_null);
}

static bool tag_is_omap(c4::csubstr tag)
{
    std::string t(tag.str, tag.len);
    return t == "!!omap" || t == "tag:yaml.org,2002:omap" || t == "<tag:yaml.org,2002:omap>";
}

static Object map_to_ruby(ryml::ConstNodeRef const& node)
{
    Hash hash;
    for (ryml::ConstNodeRef child : node.children())
        hash[node_key_to_ruby(child)] = node_to_ruby(child);
    return hash;
}

static Object seq_omap_to_ruby(ryml::ConstNodeRef const& node)
{
    // !!omap: each child is a single-key mapping; emit as array of hashes.
    Array arr;
    for (ryml::ConstNodeRef child : node.children()) {
        if (child.is_map()) {
            arr.push(map_to_ruby(child));
        } else {
            arr.push(node_to_ruby(child));
        }
    }
    return arr;
}

static Object seq_to_ruby(ryml::ConstNodeRef const& node)
{
    if (node.has_val_tag() && tag_is_omap(node.val_tag()))
        return seq_omap_to_ruby(node);
    Array arr;
    for (ryml::ConstNodeRef child : node.children())
        arr.push(node_to_ruby(child));
    return arr;
}

// --------------------------------------------------------------------------
// Tree walker
// --------------------------------------------------------------------------

static Object node_to_ruby(ryml::ConstNodeRef const& node)
{
    // STREAM — wrap multiple documents in an array; unwrap single doc
    if (node.is_stream()) {
        ryml::id_type ndocs = node.num_children();
        if (ndocs == 0) return Object(Qnil);
        if (ndocs == 1) return node_to_ruby(node[0]);
        Array arr;
        for (ryml::ConstNodeRef child : node.children())
            arr.push(node_to_ruby(child));
        return arr;
    }

    // DOC wrapper — the doc IS the map/seq/scalar; don't descend into node[0]
    if (node.is_doc()) {
        if (node.has_val())
            return node_val_to_ruby(node);
        if (node.is_map())
            return map_to_ruby(node);
        if (node.is_seq())
            return seq_to_ruby(node);
        return Object(Qnil);
    }

    if (node.is_map())
        return map_to_ruby(node);

    if (node.is_seq())
        return seq_to_ruby(node);

    if (node.has_val())
        return node_val_to_ruby(node);

    return Object(Qnil);
}

// --------------------------------------------------------------------------
// Ruby → ryml tree
// --------------------------------------------------------------------------

// Returns an arena-interned csubstr for a Ruby string/symbol value.
static c4::csubstr ruby_str_to_arena(ryml::Tree& tree, VALUE v)
{
    if (rb_type(v) == T_SYMBOL) v = rb_sym_to_s(v);
    std::string s(RSTRING_PTR(v), (size_t)RSTRING_LEN(v));
    return tree.copy_to_arena(ryml::to_csubstr(s));
}

// Forward declaration
static void ruby_val_to_node(ryml::NodeRef node, VALUE val);

// Writes val into node, which may already have a key set (map child).
// Sets MAP/SEQ/VAL type flags and populates children recursively.
static void ruby_val_to_node(ryml::NodeRef node, VALUE val)
{
    int type = rb_type(val);

    if (type == T_NIL) {
        node |= ryml::VAL;
        node.set_val(node.tree()->copy_to_arena(ryml::to_csubstr("~")));
        return;
    }
    if (type == T_TRUE) {
        node |= ryml::VAL;
        node.set_val(node.tree()->copy_to_arena(ryml::to_csubstr("true")));
        return;
    }
    if (type == T_FALSE) {
        node |= ryml::VAL;
        node.set_val(node.tree()->copy_to_arena(ryml::to_csubstr("false")));
        return;
    }
    if (type == T_FIXNUM || type == T_BIGNUM) {
        node |= ryml::VAL;
        node.set_val(node.tree()->to_arena(NUM2LL(val)));
        return;
    }
    if (type == T_FLOAT) {
        node |= ryml::VAL;
        node.set_val(node.tree()->to_arena(NUM2DBL(val)));
        return;
    }
    if (type == T_SYMBOL) {
        // Emit as ":name" plain scalar — matches Psych's wire format.
        // Empty symbol uses single-quote to prevent misreading as a tag.
        VALUE name = rb_sym_to_s(val);
        std::string sym_name(RSTRING_PTR(name), (size_t)RSTRING_LEN(name));
        if (sym_name.empty()) {
            // Psych emits `--- !ruby/symbol\n` for empty symbol; we approximate
            // with a single-quoted empty-colon string that round-trips correctly.
            c4::csubstr s = node.tree()->copy_to_arena(ryml::to_csubstr(":"));
            node |= ryml::VAL | ryml::VAL_SQUO;
            node.set_val(s);
        } else {
            std::string colon_name = ":" + sym_name;
            c4::csubstr s = node.tree()->copy_to_arena(ryml::to_csubstr(colon_name));
            node |= ryml::VAL;
            node.set_val(s);
        }
        return;
    }
    if (type == T_STRING) {
        c4::csubstr s = ruby_str_to_arena(*node.tree(), val);
        if (s.len == 0) {
            // Empty string must be quoted so it round-trips as "" not null.
            node |= ryml::VAL | ryml::VAL_SQUO;
        } else {
            node |= ryml::VAL;
        }
        node.set_val(s);
        return;
    }
    // Date and Time — emit via strftime so they round-trip cleanly.
    // T_DATA covers both; distinguish by class name.
    if (type == T_DATA || type == T_OBJECT) {
        VALUE klass = CLASS_OF(val);
        VALUE klass_name = rb_class_name(klass);
        std::string class_name(RSTRING_PTR(klass_name), (size_t)RSTRING_LEN(klass_name));
        if (class_name == "Date") {
            VALUE str = rb_funcall(val, rb_intern("strftime"), 1,
                                   rb_str_new_cstr("%Y-%m-%d"));
            c4::csubstr s = ruby_str_to_arena(*node.tree(), str);
            node |= ryml::VAL;
            node.set_val(s);
            return;
        }
        if (class_name == "Time") {
            VALUE result = rb_funcall(val, rb_intern("strftime"), 1,
                                      rb_str_new_cstr("%Y-%m-%d %H:%M:%S.%N %z"));
            std::string ts(RSTRING_PTR(result), (size_t)RSTRING_LEN(result));
            // Reformat trailing offset "+HHMM" → "+HH:MM", "+0000" → "Z"
            if (ts.size() >= 5) {
                std::string offset = ts.substr(ts.size() - 5);
                ts = ts.substr(0, ts.size() - 5);
                if (offset == "+0000" || offset == "-0000") {
                    ts += "Z";
                } else {
                    ts += offset.substr(0, 3) + ":" + offset.substr(3);
                }
            }
            c4::csubstr s = node.tree()->copy_to_arena(ryml::to_csubstr(ts));
            node |= ryml::VAL;
            node.set_val(s);
            return;
        }
    }
    if (type == T_ARRAY) {
        node |= ryml::SEQ;
        long len = RARRAY_LEN(val);
        for (long i = 0; i < len; ++i)
            ruby_val_to_node(node.append_child(), rb_ary_entry(val, i));
        return;
    }
    if (type == T_HASH) {
        node |= ryml::MAP;
        VALUE keys = rb_funcall(val, rb_intern("keys"), 0);
        long len = RARRAY_LEN(keys);
        for (long i = 0; i < len; ++i) {
            VALUE k = rb_ary_entry(keys, i);
            VALUE v = rb_hash_aref(val, k);
            ryml::NodeRef child = node.append_child();
            child |= ryml::KEY;
            // Normalize key to string before interning into the arena.
            VALUE k_str = (rb_type(k) == T_STRING || rb_type(k) == T_SYMBOL)
                              ? k
                              : rb_funcall(k, rb_intern("to_s"), 0);
            child.set_key(ruby_str_to_arena(*node.tree(), k_str));
            ruby_val_to_node(child, v);
        }
        return;
    }
    // Fallback: to_s
    VALUE str = rb_funcall(val, rb_intern("to_s"), 0);
    node |= ryml::VAL;
    node.set_val(ruby_str_to_arena(*node.tree(), str));
}

// --------------------------------------------------------------------------
// Ruby-facing functions
// --------------------------------------------------------------------------

static Object ext_parse(String input)
{
    std::string src = input.str();
    ryml::Tree tree;
    try {
        tree = ryml::parse_in_arena(ryml::to_csubstr(src));
        // Expand all anchors and aliases in-place so node_to_ruby sees plain values.
        tree.resolve();
    } catch (RymlParseError const& e) {
        throw Rice::Exception(rb_eRapidYAMLSyntaxError, "%s", e.what());
    } catch (std::exception const& e) {
        throw Rice::Exception(rb_eRapidYAMLError, "%s", e.what());
    }
    return node_to_ruby(tree.rootref());
}

// Always returns an Array of documents, even for a single-document stream.
static Array ext_parse_stream(String input)
{
    std::string src = input.str();
    ryml::Tree tree;
    try {
        tree = ryml::parse_in_arena(ryml::to_csubstr(src));
        tree.resolve();
    } catch (RymlParseError const& e) {
        throw Rice::Exception(rb_eRapidYAMLSyntaxError, "%s", e.what());
    } catch (std::exception const& e) {
        throw Rice::Exception(rb_eRapidYAMLError, "%s", e.what());
    }
    Array arr;
    ryml::ConstNodeRef root = tree.rootref();
    if (root.is_stream()) {
        for (ryml::ConstNodeRef child : root.children()) {
            // Skip empty/comment-only documents (DOC node with no real content).
            if (child.is_doc() && !child.has_val() && !child.is_map() && !child.is_seq())
                continue;
            arr.push(node_to_ruby(child));
        }
    } else if (root.num_children() > 0 || root.is_map() || root.is_seq() ||
               (root.has_val() && !root.type().has_any(ryml::VALNIL))) {
        arr.push(node_to_ruby(root));
    }
    return arr;
}

static String ext_ryml_version()
{
    return String(RYML_VERSION);
}

static String ext_emit(Object obj)
{
    try {
        ryml::Tree tree;
        ruby_val_to_node(tree.rootref(), obj.value());
        std::string yaml = ryml::emitrs_yaml<std::string>(tree);
        return String(yaml.c_str());
    } catch (std::exception const& e) {
        throw Rice::Exception(rb_eRapidYAMLError, "%s", e.what());
    }
}

// --------------------------------------------------------------------------
// Init
// --------------------------------------------------------------------------

extern "C" void Init_rapidyaml()
{
    // Install throwing error callbacks so parse errors raise Ruby exceptions
    // rather than calling abort(). Must happen before any ryml operations.
    ryml::Callbacks cb = ryml::get_callbacks();
    cb.m_error_basic = throwing_error_basic;
    cb.m_error_parse = throwing_error_parse;
    cb.m_error_visit = throwing_error_visit;
    ryml::set_callbacks(cb);

    Module rb_mRapidYAML = Rice::define_module("RapidYAML");

    // RapidYAML::Error — base for all library errors (mirrors Psych::Exception)
    rb_eRapidYAMLError = rb_define_class_under(
        rb_mRapidYAML.value(), "Error", rb_eStandardError);

    // RapidYAML::SyntaxError — raised on invalid YAML input (mirrors Psych::SyntaxError)
    rb_eRapidYAMLSyntaxError = rb_define_class_under(
        rb_mRapidYAML.value(), "SyntaxError", rb_eRapidYAMLError);

    Module rb_mExt = Rice::define_module_under(rb_mRapidYAML, "Ext");
    rb_mExt.define_module_function("parse",        &ext_parse);
    rb_mExt.define_module_function("parse_stream", &ext_parse_stream);
    rb_mExt.define_module_function("emit",         &ext_emit);
    rb_mExt.define_module_function("ryml_version", &ext_ryml_version);
}
