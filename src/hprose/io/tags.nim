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
# hprose/io/tags.nim                                       #
#                                                          #
# hprose tags for Nim                                      #
#                                                          #
# LastModified: Mar 4, 2016                                #
# Author: Ma Bingyao <andot@hprose.com>                    #
#                                                          #
############################################################

const
    # Serialize Tags
    tag_integer*    = 'i'
    tag_long*       = 'l'
    tag_double*     = 'd'
    tag_null*       = 'n'
    tag_empty*      = 'e'
    tag_true*       = 't'
    tag_false*      = 'f'
    tag_nan*        = 'N'
    tag_infinity*   = 'I'
    tag_date*       = 'D'
    tag_time*       = 'T'
    tag_utc*        = 'Z'
    tag_bytes*      = 'b'
    tag_utf8char*   = 'u'
    tag_string*     = 's'
    tag_guid*       = 'g'
    tag_list*       = 'a'
    tag_map*        = 'm'
    tag_class*      = 'c'
    tag_object*     = 'o'
    tag_ref*        = 'r'
    # Serialize Marks
    tag_pos*        = '+'
    tag_neg*        = '-'
    tag_semicolon*  = ';'
    tag_openbrace*  = '{'
    tag_closebrace* = '}'
    tag_quote*      = '"'
    tag_point*      = '.'
    # Protocol Tags
    tag_functions*  = 'F'
    tag_call*       = 'C'
    tag_result*     = 'R'
    tag_argument*   = 'A'
    tag_error*      = 'E'
    tag_end*        = 'z'
