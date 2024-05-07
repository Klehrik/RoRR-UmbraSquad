-- Umbra Squad v1.0.0
-- Klehrik

log.info("Successfully loaded ".._ENV["!guid"]..".")
mods.on_all_mods_loaded(function() for k, v in pairs(mods) do if type(v) == "table" and v.hfuncs then Helper = v end end end)

local spawn_umbras = false


-- Parameters
local damage_multiplier         = 0.25      -- Multiplied off of the player's damage
local speed_multiplier          = 1.25
local attack_speed_multiplier   = 1.5
local max_player_distance       = 1200.0    -- Max distance before teleporting to player (in pixels)



-- ========== Main ==========

gm.pre_script_hook(gm.constants.__input_system_tick, function(self, other, result, args)
    player = Helper.get_client_player()

    -- Spawn umbras on new stage (not on multiplayer)
    if spawn_umbras and player and player.activity ~= 92.0 and player.m_id == 0.0 then
        spawn_umbras = false

        local umbras = {gm.constants.oUmbraA, gm.constants.oUmbraB, gm.constants.oUmbraC, gm.constants.oUmbraD}
        for i = 1, 4 do
            local umbra = gm.instance_create_depth(player.x, player.y, -1.0, umbras[i])
            umbra.ally_umbra = true
            umbra.team = 1.0
            umbra.pHmax = umbra.pHmax * speed_multiplier
            umbra.pHmax_base = umbra.pHmax
            umbra.attack_speed = attack_speed_multiplier
        end
    end
end)


gm.post_script_hook(gm.constants.step_actor, function(self, other, result, args)
    if self.ally_umbra then
        local player = Helper.get_client_player()

        -- Make invincible and modify damage
        self.invincible = 2.0
        self.damage = player.damage * damage_multiplier
        self.damage_base = self.damage


        -- Teleport to player if too far away
        -- or if about to die to a pit
        local player_dist = gm.point_distance(self.x, self.y, player.x, player.y)
        local player_is_climbing = player.activity == 92.0 and player.activity_type == 2.0

        if (player_dist > max_player_distance and player.pVspeed == 0.0 and (not player_is_climbing) and self.activity == 0.0)
        or self.y >= gm.variable_global_get("room_height") then
            self.x, self.y = player.x, player.y
        end


        -- Targeting behavior
        -- Loop through actors and find the closest hostile
        -- If none, follow (target) the player
        local actors = Helper.find_active_instance_all(gm.constants.pActor)
        local dist = 100000.0
        local target = nil

        for _, a in ipairs(actors) do
            local d = gm.point_distance(self.x, self.y, a.x, a.y)
            if a.team ~= self.team and d < dist then
                dist = d
                target = a
            end
        end

        if self.target ~= -4.0 then
            if target then self.target.parent = target
            else
                self.target.parent = player

                -- Prevent attacking if target is player
                -- Doesn't work well for HAN-D umbra so removed for now
                -- if self.activity == 92.0 and self.activity_type ~= 2.0 then
                --     self.activity = 0.0
                --     self.activity_free = true
                --     self.activity_move_factor = 1.0
                --     self.activity_type = 0.0
                --     self.activity_var1 = 0.0
                --     self.activity_var2 = 0.0
                -- end
            end
        end
    end
end)


gm.post_script_hook(gm.constants.stage_roll_next, function(self, other, result, args)
    spawn_umbras = true
end)

gm.post_script_hook(gm.constants.stage_goto, function(self, other, result, args)
    spawn_umbras = true
end)