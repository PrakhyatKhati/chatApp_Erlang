

-module(chatApp_server).
-author('Prakhyat Khati <khati.prakhyat@usask.ca').

-export([start/0,start/1,stop/1]).
start() -> start(8080).
start(Port) ->

 % Message will be printed as the server starts. 
    io:format("Server has been started ~n"),
    % Dictionary to hold UserIds and socket information. 
    Client_key =dict:new(),
    Client_value =dict:new(),
    % Link create two process (insert and lookups)
    % It return the process indentifier of the new process started buy the application module
    Dict_Processid = spawn_link(fun() -> client_handle(Client_key, Client_value) end),
    
    chatApp_listener:listen(Port,Dict_Processid).

client_handle(Client_key,Client_value) ->
    receive
        {new_client,Socket,UserId}->
            %passing list of arrgument
            io:format("Adding New User ~p~n", [UserId]),
            Temp_Clients_key = dict:store(UserId,Socket,Client_key),
            Temp_values_key = dict:store(Socket, UserId, Client_value),

            client_handle(Temp_Clients_key, Temp_values_key);

        % clients process id and userid 
        {client_pid, Receive_keys, UserId} ->
            {ok, Cpid}= dict:find(UserId, Client_key),
            %sending message 
            Receive_keys ! {pid, Cpid},
            client_handle(Client_key, Client_value);

        % Getting the Username of the new clients.
        {get_UserId, Receive_keys,Process_id}->
            {ok, ClientId} = dict:find(Process_id,Client_value),
            %Sending Message
            Receive_keys ! {client_id,ClientId},
            client_handle(Client_key, Client_value );

        % Getting all the cliens key values
        {get_allpids,Receive_keys} ->
            Receive_keys ! {all_pids, Client_key},
            client_handle(Client_key, Client_value);
        
        % error handling
        _ ->
             {error, "Error occured !! The action is not permited !!"}
    end.

stop(Socket) ->
    get_tcp:close(Socket).




            


    

    



