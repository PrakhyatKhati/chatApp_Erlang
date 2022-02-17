-module(chatApp_listener).
-author('Prakhyat Khati <khati.prakhyat@usask.ca').

-define(TCP_OPTIONS, [binary, {packet, 2}, {active, false}, {reuseaddr, true}]).
%%=======
%API functions.
%%=======
-export([listen/2]).

listen(Port, Dict_Processid) ->
        % create a listener on a listening socket
        {ok, LSocket} = gen_tcp:listen(Port, ?TCP_OPTIONS),
        spawn_link(fun() -> accept(LSocket, Dict_Processid) end),
        io:format(" Server is Listening on socket =~p~n", [LSocket]).

%accept incoming connection and handle the icoming packet., 

accept(LSocket, Dict_Processid) ->
    {ok, Socket}= gen_tcp:accept(LSocket),
    Process_id = spawn(fun() ->
             io:format("Connection established  ~n",[]),
            loop(Socket, Dict_Processid)
            end),
    gen_tcp:controlling_process(Socket, Process_id),
    accept(LSocket,Dict_Processid).

% this fucntion handles the data and figure out the right action 
%

loop(Sockid, Dict_Processid) ->
    %temp values is set to active
    inet:setopts(Sockid, [{active, once}]),
    receive 
        {tcp, Socket, UserData} ->
            %% figure out the data.
            User_Processed_Data = user_action(Socket, UserData,Dict_Processid),
            send_message(Socket, User_Processed_Data), % sending message to the sender
            loop(Socket,Dict_Processid);
        {tcp_closed,Socket} ->
            io:format("~p left.~n", [Socket]);

        {tcp_error, Socket, Reason} ->
            io:format("Error on socket ~p, Reason: ~p~n",[Socket, Reason])
    end.

%% sending message to the individual, group  and handle all of the client actions.

user_action(Socket, UserData, Dict_Processid) ->
    case binary_to_term(UserData) of 
        % someone joins the chat room 
        {signup, UserId} ->
         %tell dictionary to add the new client 
            Dict_Processid ! {new_client, Socket, UserId};
        {send_to, UserId, Message} ->
        %Searching a process ID and socket ID
        %First get sender P
        Dict_Processid ! {get_UserId, self(), Socket},
        receive
            {client_id, ClientId}->
                    Sender = ClientId;
            _ -> Sender = "Anonymous client"
        end,
        FormattedMessage = lists:concat([Sender,"> ", Message]),

        Dict_Processid ! {client_pid,self(), UserId},
        receive
        {pid, SockPid} ->
        gen_tcp:send(SockPid, term_to_binary(FormattedMessage))
        end,
        
            term_to_binary({ok, delivered});

        %message everyone
        {broadcast, Message} ->

            %fisrt get sender's Pid

            Dict_Processid ! {get_UserId, self(), Socket},
            receive
                {client_id,ClientId} ->
                             Sender = ClientId;
                    _ -> Sender = "Anonymous"
                end,
                

            FormattedMessage = lists:concat([Sender,"> ", Message]),
            
            Dict_Processid ! {get_allpids, self()},
            receive
                    {all_pids,Pids} ->
                        dict:map(fun(K,V) ->
                        io:format("All key values being processed: ~w: ~w~n",[K,V]),
                        gen_tcp:send(V, term_to_binary(FormattedMessage))end, Pids)
            end,
            term_to_binary({ok, delivered});

    _ ->{error,"Error occured !! The action is not permited !!"}
    end.

send_message(Socket, Bin) ->
    gen_tcp:send(Socket, Bin).









