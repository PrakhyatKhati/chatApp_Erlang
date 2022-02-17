

-module(chatApp_client).
-author('Prakhyat Khati <khati.prakhyat@usask.ca').

-define(TCP_OPTIONS, [binary, {packet, 2}, {active, false}, {reuseaddr, true}]).

-export([connect/0, connect/1, send/2, disconnect/1,recv/1]).

connect() -> connect (8080).
connect(Port) ->
    {ok, Socket}= gen_tcp:connect("localhost",Port,?TCP_OPTIONS),
    spawn(fun() -> recv(Socket) end),
    Socket.

% sending message from the client. 
send(Socket, Message) ->
    % Need to chage to binary for sending it to the socket. 
    Bin = term_to_binary(Message),
    gen_tcp:send(Socket, Bin).
    
%creating a function that just handles incoming messages

recv(Socket) ->
    case gen_tcp:recv(Socket, 0) of
        {ok, Bin} ->
            Answer = binary_to_term(Bin),
            io:format("~p~n",[Answer]),
                recv(Socket);
        {error, Reason} ->
            io:format("Error :~p~n",[Reason]),
        ok    

    end.



%User can leave the chat 
disconnect(Socket) ->
    gen_tcp:close(Socket).

