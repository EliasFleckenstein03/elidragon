elidragon.ranks = {
	{
        name = "player",
        privs = {interact = true, shout = true, home = true, tp = true},
        color = "#FFFFFF",
        tag = "",
    },
    {
		name = "vip",
		privs = {fly = true, fast = true},
		color = "#16AE00",
		tag = "[VIP]",
	},
	{
		name = "builder",
		privs = {creative = true, areas = true},
		color = "#EE6E00",
		tag = "[Builder]",
	},
	{
		name = "helper",
		privs = {kick = true, noclip = true, settime = true, give = true, teleport = true, watch = true},
		color = "#EBEE00",
		tag = "[Helper]",
	},
	{
		name = "moderator",
		privs = {ban = true, bring = true, invhack = true, vanish = true, protection_bypass = true, worldedit = true},
		color = "#001FFF",
		tag = "[Moderator]",
	},
	{
		name = "developer",
		privs = {server = true, privs = true},
		color = "#900A00",
		tag = "[Developer]",
	},
	{
		name = "admin",
		privs = {},
		color = "#FF2D8D",
		tag = "[Admin]",
	},
}

local s = minetest.get_mod_storage()
local deferred = minetest.deserialize(s:get_string("deferred_rank_changes"))

function elidragon.get_rank(player)
    local rank = player:get_meta():get_string("elidragon:rank")
    if not rank or rank == "" then rank = "player" end
    return elidragon.get_rank_by_name(rank)
end

function elidragon.get_rank_by_name(rankname)
	for i, rank in pairs(elidragon.ranks) do
		if rank.name == rankname then
			return rank, i
		end
	end
end

function elidragon.get_player_name(player, color, brackets)
    local rank = elidragon.get_rank(player)
    local rank_tag = rank.tag
    if color then 
		rank_tag = minetest.colorize(rank.color, rank_tag)
	end
	if not brackets then 
		brackets = {"",""}
	end
	return rank_tag .. brackets[1] .. player:get_player_name() .. brackets[2] .. " "
end

function elidragon.update_nametag(player)
	player:set_nametag_attributes({color = elidragon.get_rank(player).color})
end

minetest.register_on_joinplayer(function(player)
    minetest.chat_send_all(elidragon.get_player_name(player, true) .. "has joined the Server.")
    if irc and irc.connected and irc.config.send_join_part then
        irc.say(elidragon.get_player_name(player) .. "has joined the Server.")
    end
    elidragon.update_nametag(player)
end)

minetest.register_on_leaveplayer(function(player)
    minetest.chat_send_all(elidragon.get_player_name(player, true) .. "has left the Server.")
    if irc and irc.connected and irc.config.send_join_part then
        irc.say(elidragon.get_player_name(player) .. "has left the Server.")
    end
end)

minetest.register_on_chat_message(function(name, message)
	local player = minetest.get_player_by_name(name)
	if not player or not minetest.check_player_privs(name, {shout = true}) then return end
    minetest.chat_send_all(elidragon.get_player_name(player, true, {"<", ">"}) .. message)
    if irc and irc.connected and irc.joined_players[name] then
        irc.say(elidragon.get_player_name(player, false, {"<", ">"}) .. message)
    end
    return true
end)

minetest.register_chatcommand("rank", {
	params = "<player> <rank>",
	description = "Set a player's rank (admin|developer|moderator|helper|builder|vip|player)",
	privs = {privs = true},
	func = function(name, param)
		local set_rank = function()
			local privs = {}
			for _, r in pairs(elidragon.ranks) do
				for k, v in pairs(r.privs) do
					privs[k] = v
				end
				if r.name == rank then
					break
				end
			end
			minetest.set_player_privs(target, privs)
			minetest.chat_send_all(target .. " is now a " .. minetest.colorize(rank_ref.color, rank_ref.name))
		end

		local target = param:split(" ")[1] or ""
		local rank = param:split(" ")[2] or ""
		local target_ref = minetest.get_player_by_name(target)
		local rank_ref = elidragon.get_rank_by_name(rank)
		if not rank_ref then 
			return false, "Invalid Rank: " .. rank
		elseif not target_ref then
			deferred[target] = rank
			set_rank()
		else
			target_ref:get_meta():set_string("elidragon:rank", rank)
			set_rank()
			elidragon.update_nametag(target_ref)
		end
	end,
})

minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	if deferred[name] then
		player:get_meta():set_string("elidragon:rank", deferred[name])
		elidragon.update_nametag(player)
		deferred[name] = nil
	end
end)

minetest.register_on_shutdown(function()
	s:set_string("deferred_rank_changes", minetest.serialize(deferred))
end)
