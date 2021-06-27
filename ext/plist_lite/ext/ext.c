#include "ruby.h"
#include "ruby/encoding.h"
#include <stdint.h>
#include <stdlib.h>

typedef struct
{
  char *head;
  size_t size;
  size_t length;
} string;

string *string_new(size_t size)
{
  string *ptr = malloc(sizeof(string));
  ptr->size = size;
  ptr->head = malloc(size);
  ptr->head[0] = '\0';
  ptr->length = 0;
  return ptr;
}

void string_concat(string *recv, char *src)
{
  size_t len_src = strlen(src);
  size_t new_size = recv->size;
  while ((recv->length + len_src + 1) > new_size)
    new_size <<= 1;
  if (new_size > recv->size)
    recv->head = realloc(recv->head, new_size);

  char *ptr = recv->head + recv->length;
  while ((*ptr++ = *src++))
    ;
  recv->length += len_src;
}

void string_free(string *recv)
{
  free(recv->head);
  free(recv);
}

void time_to_plist_date(VALUE time, string *output)
{
  rb_funcall(time, rb_intern("utc"), 0);
  VALUE str = rb_funcall(time, rb_intern("iso8601"), 0);
  string_concat(output, (char *)"<date>");
  string_concat(output, StringValueCStr(str));
  string_concat(output, (char *)"</date>");
}

void dump_node(VALUE obj, string *output);

VALUE to_utf8_xml_text(VALUE obj)
{
  int idx = rb_enc_get_index(obj);
  if (idx < 0)
    rb_raise(rb_eTypeError, "unknown encoding");
  if (idx == rb_utf8_encindex())
  {
    VALUE options = rb_hash_new();
    rb_hash_aset(options, ID2SYM(rb_intern("xml")), ID2SYM(rb_intern("text")));
    return rb_funcallv_kw(obj, rb_intern("encode"), 1, &options, RB_PASS_KEYWORDS);
  }
  else
  {
    VALUE options = rb_hash_new();
    rb_hash_aset(options, ID2SYM(rb_intern("xml")), ID2SYM(rb_intern("text")));
    VALUE args[] = {rb_enc_from_encoding(rb_utf8_encoding()), options};
    return rb_funcallv_kw(obj, rb_intern("encode"), 2, args, RB_PASS_KEYWORDS);
  }
}

VALUE array_each_block(VALUE obj, string *output)
{
  dump_node(obj, output);
  return Qnil;
}

VALUE hash_each_block(VALUE pair, string *output)
{
  VALUE value = rb_ary_pop(pair);
  VALUE key = rb_ary_pop(pair);
  string_concat(output, (char *)"<key>");
  switch (TYPE(key))
  {
  case T_STRING:
  {
    VALUE encoded = to_utf8_xml_text(key);
    string_concat(output, StringValueCStr(encoded));
    break;
  }
  case T_SYMBOL:
  {
    VALUE str = rb_funcall(key, rb_intern("to_s"), 0);
    string_concat(output, StringValueCStr(str));
    break;
  }
  default:
  {
    VALUE encoded = to_utf8_xml_text(rb_funcall(key, rb_intern("to_s"), 0));
    string_concat(output, StringValueCStr(encoded));
    break;
  }
  }
  string_concat(output, (char *)"</key>");
  dump_node(value, output);
  return Qnil;
}

void dump_node(VALUE obj, string *output)
{
  switch (TYPE(obj))
  {
  case T_ARRAY:
    string_concat(output, (char *)"<array>");
    rb_block_call(obj, rb_intern("each"), 0, NULL, (rb_block_call_func_t)array_each_block, (VALUE)output);
    string_concat(output, (char *)"</array>");
    break;
  case T_HASH:
    string_concat(output, (char *)"<dict>");
    rb_block_call(obj, rb_intern("each"), 0, NULL, (rb_block_call_func_t)hash_each_block, (VALUE)output);
    string_concat(output, (char *)"</dict>");
    break;
  case T_TRUE:
    string_concat(output, (char *)"<true/>");
    break;
  case T_FALSE:
  {
    string_concat(output, (char *)"<false/>");
    break;
  }
  case T_BIGNUM:
  case T_FIXNUM:
  {
    VALUE str = rb_funcall(obj, rb_intern("to_s"), 0);
    string_concat(output, (char *)"<integer>");
    string_concat(output, StringValueCStr(str));
    string_concat(output, (char *)"</integer>");
    break;
  }
  case T_FLOAT:
  {
    VALUE str = rb_funcall(obj, rb_intern("to_s"), 0);
    string_concat(output, (char *)"<real>");
    string_concat(output, StringValueCStr(str));
    string_concat(output, (char *)"</real>");
    break;
  }
  case T_STRING:
  {
    int idx = rb_enc_get_index(obj);
    if (idx == rb_ascii8bit_encindex())
    {
      string_concat(output, (char *)"<data>");
      VALUE data = rb_funcall(
          rb_ary_new_from_values(1, &obj),
          rb_intern("pack"),
          1,
          rb_str_new_literal("m"));
      string_concat(output, StringValueCStr(data));
      string_concat(output, (char *)"</data>");
    }
    else
    {
      string_concat(output, (char *)"<string>");
      VALUE encoded = to_utf8_xml_text(obj);
      string_concat(output, StringValueCStr(encoded));
      string_concat(output, (char *)"</string>");
    }

    break;
  }
  case T_SYMBOL:
  {
    VALUE str = rb_funcall(obj, rb_intern("to_s"), 0);
    string_concat(output, (char *)"<string>");
    string_concat(output, StringValueCStr(str));
    string_concat(output, (char *)"</string>");
    break;
  }
  default:
  {
    if (rb_obj_is_kind_of(obj, rb_cTime) == Qtrue)
    {
      VALUE time = rb_funcall(rb_cTime, rb_intern("at"), 1, obj);
      time_to_plist_date(time, output);
    }
    else if (rb_obj_is_kind_of(obj, rb_const_get(rb_cObject, rb_intern("DateTime"))) == Qtrue)
    {
      VALUE time = rb_funcall(obj, rb_intern("to_time"), 0);
      time_to_plist_date(time, output);
    }
    else if (rb_obj_is_kind_of(obj, rb_const_get(rb_cObject, rb_intern("Date"))) == Qtrue)
    {
      rb_warn("Consider not using Date object because it does not contain time zone information");
      VALUE str = rb_funcall(obj, rb_intern("iso8601"), 0);
      string_concat(output, (char *)"<date>");
      string_concat(output, StringValueCStr(str));
      string_concat(output, (char *)"T00:00:00Z</date>");
    }
    else
    {
      VALUE msg = rb_funcall(rb_obj_class(obj), rb_intern("to_s"), 0);
      rb_raise(rb_eArgError, "Unsupported type: %s", StringValueCStr(msg));
    }
    break;
  }
  }
}

VALUE dump(VALUE recv, VALUE obj)
{
  string *output = string_new(2048);
  string_concat(
      output,
      (char *)"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
              "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">"
              "<plist version=\"1.0\">");
  dump_node(obj, output);
  string_concat(output, (char *)"</plist>");
  VALUE ret = rb_utf8_str_new(output->head, output->length);
  string_free(output);
  return ret;
}

void Init_ext(void)
{
  rb_require("time");
  VALUE cPlistLite = rb_define_module("PlistLite");
  rb_define_singleton_method(cPlistLite, "dump", dump, 1);
}
