print("Client side init")

_G.client_scripts = {}

-- util function for including/reloading scripts

concommand.Add("cl_load_script", function(player, cmd, args, argstr)
	if args[1] == nil then
		print("Usage: cl_load_script <script name>")
	end 
	includeCS(args[1])

	for k,v in pairs(client_scripts) do
		if k == args[1] then 
			return
		end 
	end 
	table.insert(client_scripts, args[1])
end) 

concommand.Add("cl_reload_scripts", function(player, cmd, args, argstr)
	for k,v in pairs(client_scripts) do
		includeCS(k)
	end 
end)
