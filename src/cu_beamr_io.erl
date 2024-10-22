-module(cu_beamr_io).
-export([size/1, read/3, write/3]).
-export([read_string/2, write_string/2]).
-export([malloc/2, free/2]).

-include("include/ao.hrl").

size(Port) ->
    Port ! {self(), {command, term_to_binary({size})}},
    receive
        {ok, Size} ->
            {ok, Size};
        Error ->
            Error
    end.

write(Port, Offset, Data) when is_binary(Data) ->
    ?c(writing_to_mem),
    Port ! {self(), {command, term_to_binary({write, Offset, Data})}},
    ?c(mem_written),
    receive
        ok ->
            ok;
        Error ->
            Error
    end.

write_string(Port, Data) when is_list(Data) ->
    write_string(Port, iolist_to_binary(Data));
write_string(Port, Data) when is_binary(Data) ->
    DataSize = byte_size(Data) + 1,
    String = <<Data/bitstring, 0:8>>,
    case malloc(Port, DataSize) of
        {ok, Ptr} ->
            case write(Port, Ptr, String) of
                ok ->
                    {ok, Ptr};
                Error ->
                    free(Port, Ptr),
                    Error
            end;
        Error ->
            Error
    end.

read(Port, Offset, Size) ->
    Port ! {self(), {command, term_to_binary({read, Offset, Size})}},
    receive
        {ok, Result} -> {ok, Result}
    end.

read_string(Port, Offset) ->
    {ok, iolist_to_binary(do_read_string(Port, Offset, 8))}.

do_read_string(Port, Offset, ChunkSize) ->
    {ok, Data} = read(Port, Offset, ChunkSize),
    case binary:split(Data, [<<0>>]) of
        [Data|[]] -> [Data|do_read_string(Port, Offset + ChunkSize, ChunkSize)];
        [FinalData|_Remainder] -> [FinalData]
    end.



malloc(Port, Size) ->
    case cu_beamr:call(Port, "malloc", [Size]) of
        {ok, [0]} ->
            ?c({malloc_failed, Size}),
            {error, malloc_failed};
        {ok, [Ptr]} ->
            ?c({malloc_success, Ptr, Size}),
            {ok, Ptr};
        {error, Error} ->
            {error, Error}
    end.

free(Port, Ptr) ->
    case cu_beamr:call(Port, "free", [Ptr]) of
        {ok, Res} ->
            ?c({free_result, Res}),
            ok;
        {error, Error} ->
            {error, Error}
    end.