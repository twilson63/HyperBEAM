-module(info_http).

-export([routes/0, handle/3]).

-include("src/include/ao.hrl").

routes() ->
  {"/info", ["/"]}.

handle(<<"GET">>, [], Req) ->
  cowboy_req:reply(200,
                   #{<<"Content-Type">> => <<"application/json">>},
                   jiffy:encode({[{<<"Name">>, <<"Permaweb Node">>}]}),
                   Req),
  {ok, Req}.
