-module(leviathan_linux).

-compile(export_all).

%
% Cid::string() is the runtime Container ID of a running Container as shown by
% > docker ps
% 
% <type>Num (e.g. PeerNum) are internal numbers allocated by Leviathan
%


%
% set_netns(Cid)
%
% creates a new network namespace with a name that is identical the process id
% (pid) of the running Container.  
%
%  
set_netns(Cid)->
    [leviathan_bash:mkdir_p_var_run_netns(),
     leviathan_bash:ln_s_proc_ns_net_var_run_netns(leviathan_docker:inspect_pid(Cid))].

remove_netns(Cid)->
    [leviathan_bash:rm_f_var_run_netns(leviathan_docker:inspect_pid(Cid))].

%
% new_peer(Cid,PeerNum)
%
% creates a new pair of "peer" virtual interfaces and stuffs one end
% (the "i" end) inside the container and renames it 
% Eth<PeerNum>  (e.g. Eth0)
%
% A high level description of what is going here can be found here:
% http://blog.scottlowe.org/2013/09/04/introducing-linux-network-namespaces/
% https://docs.docker.com/articles/networking/#how-docker-networks-a-container
% 
%
%  
new_peer(Cid,PeerNum)->
    CPid = leviathan_docker:inspect_pid(Cid),
    LevNameOut = mk_peer_lev_name_out(Cid,PeerNum),
    LevNameIn = mk_peer_lev_name_in(Cid,PeerNum),
    [leviathan_ip:link_add_type_veth_peer_name(LevNameOut,LevNameIn),
    leviathan_ip:link_set_netns(LevNameIn,CPid),
    leviathan_ip:netns_exec_ip_link_set_dev_name(CPid,LevNameIn,mk_lev_eth_name(PeerNum))].


delete_peer(Cid,PeerNum)->
    LevNameOut = mk_peer_lev_name_out(Cid,PeerNum),
    [leviathan_ip:link_delete_type_veth_peer(LevNameOut)].
    

new_bridge(BridgeNum)->
    [leviathan_brctl:addbr(mk_lev_bridge_name(BridgeNum))].
    

mk_lev_eth_name(PeerNum)->
    "eth" ++ integer_to_list(PeerNum).

mk_lev_bridge_name(BridgeNum)->
    "levbr" ++ integer_to_list(BridgeNum).
    
mk_peer_lev_name_in(Cid,PeerNum)->
    mk_peer_lev_name_prefix(Cid,PeerNum) ++ "i".

mk_peer_lev_name_out(Cid,PeerNum)->
    mk_peer_lev_name_prefix(Cid,PeerNum) ++ "o".

mk_peer_lev_name_prefix(Cid,PeerNum)->
    Cid ++ "." ++ integer_to_list(PeerNum).


eval(CmdBundle)->
    lists:map(fun(X)->		   
		      os:cmd(X) end,CmdBundle).
    
    