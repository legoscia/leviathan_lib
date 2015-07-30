-module(leviathan_docker).

-compile(export_all).

-include("leviathan_logger.hrl").

%
% example: docker inspect -f '{{.State.Pid}}' 63f36fc01b5f
%
inspect_pid(Cid)->
    Cmd = "docker inspect -f '{{.State.Pid}}' " ++ Cid,
    Result = os:cmd(Cmd),
    Stripped = string:strip(Result,right,$\n),
    case string:to_integer(Stripped) of
	{_,[]}->
	    Stripped;
	_ -> 
	    ?DEBUG("leviathan:inspect_pid(~p) BAD Container ID ~p!",[Cid,Cid]),
	    exit(1) % for running systems
	    %%"00000" % for testing
    end.
    