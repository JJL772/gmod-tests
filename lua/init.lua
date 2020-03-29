print("Server-side lua init")


_G.server_scripts = {}

-- util function for including/reloading scripts

concommand.Add("sv_load_script", function(player, cmd, args, argstr)
	if args[1] == nil then
		print("Usage: sv_load_script <script name>")
	end 
	include(args[1])

	for k,v in pairs(server_scripts) do
		if k == args[1] then 
			return
		end 
	end 
	table.insert(server_scripts, args[1])
end) 

concommand.Add("sv_reload_scripts", function(player, cmd, args, argstr)
	for k,v in pairs(server_scripts) do
		include(k)
	end 
end)
