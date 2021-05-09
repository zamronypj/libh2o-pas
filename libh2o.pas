{*!
 * libh2o header translation for Free Pascal
 *
 * @link      https://github.com/zamronypj/libh2o-pas
 * @copyright Copyright (c) 2021 Zamrony P. Juhara
 * @license   https://github.com/zamronypj/libuv/blob/master/LICENSE (MIT)
 *}
unit libh2o;

interface

uses

    {$IFDEF UNIX}
    ctypes,
    baseunix,
    {$ENDIF}

    sysutils;

{$include h2o/filecache.inc}
{$include h2o/header.inc}
{$include h2o/hostinfo.inc}
{$include h2o/memcached.inc}
{$include h2o/redis.inc}
{$include h2o/linklist.inc}
{$include h2o/httpclient.inc}
{$include h2o/memory.h}
{$include h2o/multithread.inc}
{$include h2o/rand.inc}
{$include h2o/socket.inc}
{$include h2o/string_.inc}
{$include h2o/time_.inc}
{$include h2o/token.inc}
{$include h2o/url.inc}
{$include h2o/version.inc}
{$include h2o/balancer.inc}
{$include h2o/http2_common.inc}
{$include h2o/send_state.inc}

const

    H2O_USE_BROTLI = 0;

    H2O_MAX_HEADERS = 100;
    H2O_MAX_REQLEN = (8192 + 4096 * (H2O_MAX_HEADERS));

    { simply use a large value, and let the kernel clip it to the internal max }
    H2O_SOMAXCONN = 65535;

    H2O_HTTP2_MIN_STREAM_WINDOW_SIZE = 65535;
    H2O_HTTP2_MAX_STREAM_WINDOW_SIZE = 16777216;

    H2O_DEFAULT_MAX_REQUEST_ENTITY_SIZE = (1024 * 1024 * 1024);
    H2O_DEFAULT_MAX_DELEGATIONS = 5;
    H2O_DEFAULT_HANDSHAKE_TIMEOUT_IN_SECS = 10;
    H2O_DEFAULT_HANDSHAKE_TIMEOUT = (H2O_DEFAULT_HANDSHAKE_TIMEOUT_IN_SECS * 1000);
    H2O_DEFAULT_HTTP1_REQ_TIMEOUT_IN_SECS = 10;
    H2O_DEFAULT_HTTP1_REQ_TIMEOUT = (H2O_DEFAULT_HTTP1_REQ_TIMEOUT_IN_SECS * 1000);
    H2O_DEFAULT_HTTP1_REQ_IO_TIMEOUT_IN_SECS = 5;
    H2O_DEFAULT_HTTP1_REQ_IO_TIMEOUT = (H2O_DEFAULT_HTTP1_REQ_IO_TIMEOUT_IN_SECS * 1000);
    H2O_DEFAULT_HTTP1_UPGRADE_TO_HTTP2 = 1;
    H2O_DEFAULT_HTTP2_IDLE_TIMEOUT_IN_SECS = 10;
    H2O_DEFAULT_HTTP2_IDLE_TIMEOUT = (H2O_DEFAULT_HTTP2_IDLE_TIMEOUT_IN_SECS * 1000);
    H2O_DEFAULT_HTTP2_GRACEFUL_SHUTDOWN_TIMEOUT_IN_SECS = 0 { no timeout };
    H2O_DEFAULT_HTTP2_GRACEFUL_SHUTDOWN_TIMEOUT = (H2O_DEFAULT_HTTP2_GRACEFUL_SHUTDOWN_TIMEOUT_IN_SECS * 1000);
    H2O_DEFAULT_HTTP2_ACTIVE_STREAM_WINDOW_SIZE = H2O_HTTP2_MAX_STREAM_WINDOW_SIZE;
    H2O_DEFAULT_HTTP3_ACTIVE_STREAM_WINDOW_SIZE = H2O_DEFAULT_HTTP2_ACTIVE_STREAM_WINDOW_SIZE;
    H2O_DEFAULT_PROXY_IO_TIMEOUT_IN_SECS = 30;
    H2O_DEFAULT_PROXY_IO_TIMEOUT = (H2O_DEFAULT_PROXY_IO_TIMEOUT_IN_SECS * 1000);
    H2O_DEFAULT_PROXY_TUNNEL_TIMEOUT_IN_SECS = 300;
    H2O_DEFAULT_PROXY_SSL_SESSION_CACHE_CAPACITY = 4096;
    H2O_DEFAULT_PROXY_SSL_SESSION_CACHE_DURATION = 86400000; { 24 hours }
    H2O_DEFAULT_PROXY_HTTP2_MAX_CONCURRENT_STREAMS = 100;

type

    h2o_conn_t = st_h2o_conn_t;
    ph2o_conn_t = ^h2o_conn_t;

    h2o_context_t = st_h2o_context_t;
    ph2o_context_t = ^h2o_context_t;

    h2o_req_t = st_h2o_req_t;
    ph2o_req_t = ^h2o_req_t;

    h2o_ostream_t = st_h2o_ostream_t;
    ph2o_ostream_t = ^h2o_ostream_t;

    h2o_configurator_command_t = st_h2o_configurator_command_t;
    ph2o_configurator_command_t = ^h2o_configurator_command_t;

    h2o_configurator_t = st_h2o_configurator_t;
    ph2o_configurator_t = ^h2o_configurator_t;

    h2o_pathconf_t = st_h2o_pathconf_t;
    ph2o_pathconf_t = ^h2o_pathconf_t;

    h2o_hostconf_t = st_h2o_hostconf_t;
    ph2o_hostconf_t = ^h2o_hostconf_t;

    h2o_globalconf_t = st_h2o_globalconf_t;
    ph2o_globalconf_t = ^h2o_globalconf_t;

    h2o_mimemap_t = st_h2o_mimemap_t;
    ph2o_mimemap_t = ^h2o_mimemap_t;

    h2o_logconf_t = st_h2o_logconf_t;
    ph2o_logconf_t = ^h2o_logconf_t;

    h2o_headers_command_t = st_h2o_headers_command_t;
    ph2o_headers_command_t = ^h2o_headers_command_t;

    ph2o_handler_t = ^h2o_handler_t;
    on_context_init_cb = procedure(aself : ph2o_handler_t; ctx : ph2o_context_t); cdecl;
    on_context_dispose_cb = procedure(aself : ph2o_handler_t; ctx : ph2o_context_t); cdecl;
    dispose_cb = procedure(aself : ph2o_handler_t); cdecl;
    on_req_cb = function(aself : ph2o_handler_t; req : ph2o_req_t) : integer; cdecl;

    (**
     * basic structure of a handler (an object that MAY generate a response)
     * The handlers should register themselves to h2o_context_t::handlers.
     *)
    h2o_handler_t = record
        _config_slot : size_t;
        on_context_init : on_context_init_cb;
        on_context_dispose : on_context_dispose_cb;
        dispose : dispose_cb;
        on_req : on_req_cb;

        (**
        * If the flag is set, protocol handler may invoke the request handler before receiving the end of the request body. The request
        * handler can determine if the protocol handler has actually done so by checking if `req->proceed_req` is set to non-NULL.
        * In such case, the handler should replace `req->write_req.cb` (and ctx) with its own callback to receive the request body
        * bypassing the buffer of the protocol handler. Parts of the request body being received before the handler replacing the
        * callback is accessible via `req->entity`.
        * The request handler can delay replacing the callback to a later moment. In such case, the handler can determine if
        * `req->entity` already contains a complete request body by checking if `req->proceed_req` is NULL.
        *)
        supports_request_streaming : boolean;
    end;

    ph2o_filter_t = ^h2o_filter_t;

    on_context_init_filter_cb = procedure(aself : ph2o_filter_t; ctx : ph2o_context_t); cdecl;

    on_context_dispose_filter_cb = procedure(aself : ph2o_filter_t; ctx : ph2o_context_t); cdecl;

    dispose_filter_cb = procedure(aself : ph2o_filter_t); cdecl;

    on_setup_ostream_filter_cb = procedure(
        aself : ph2o_filter_t;
        req : ph2o_req_t;
        var slot : ph2o_ostream_t
    ); cdecl;

    on_informational_filter_cb = procedure(
        aself : ph2o_filter_t;
        req : ph2o_req_t
    ); cdecl;

    (**
     * basic structure of a filter (an object that MAY modify a response)
     * The filters should register themselves to h2o_context_t::filters.
     *)
    h2o_filter_t = record
        _config_slot : size_t;
        on_context_init : on_context_init_filter_cb;
        on_context_dispose : on_context_dispose_filter_cb;
        dispose : dispose_filter_cb;
        on_setup_ostream : on_setup_ostream_filter_cb;
        on_informational : on_informational_filter_cb;
    end;


implementation

end.
