-- debo.combat.module.lua
-- Módulo de combate modular para MUSHclient

local DeboCore = require("debo_core")
local SoundUtils = require("sound_utils")

local Combat = {}
Combat.__index = Combat
Combat.VERSION = "1.0.0"

-- Configurações específicas do combate
Combat.Settings = {
    sound_path = "sounds/SFX/Combate/",
    music_path = "BGS/battle.wav",
    music_channel = 9,
    combat_volume = -40,
    fade_speed = 5
}

-- Estado do combate (apenas dados específicos do módulo)
Combat.State = {
    last_attack_type = nil,
    combat_start_time = nil,
    total_damage_dealt = 0,
    total_damage_taken = 0
}

-- Mapeamento de tipos de ataque para pastas de som
Combat.AttackTypes = {
    ["TYPE_BITE"] = "Bite",
    ["TYPE_BLAST"] = "Blast",
    ["TYPE_BLUDGEON"] = "Bludgeon",
    ["TYPE_CLAW"] = "Claw",
    ["TYPE_CRUSH"] = "Crush",
    ["TYPE_HIT"] = "Hit",
    ["TYPE_HURT"] = "Hurt",
    ["TYPE_MAUL"] = "Maul",
    ["TYPE_MISS"] = "Miss",
    ["TYPE_PARRY"] = "Parry",
    ["TYPE_PIERCE"] = "Pierce",
    ["TYPE_POUND"] = "Pound",
    ["TYPE_PUNCH"] = "Punch",
    ["TYPE_SLASH"] = "Slash",
    ["TYPE_SHIELD"] = "Shield",
    ["TYPE_STAB"] = "Stab",
    ["TYPE_STING"] = "Sting",
    ["TYPE_THRASH"] = "Thrash",
    ["TYPE_WHIP"] = "Whip"
}

-- Inicialização do módulo
function Combat.Initialize()
    DeboCore.Info("COMBAT", "Módulo de Combate v" .. Combat.VERSION .. " inicializado")

    -- Inicializar SoundUtils
    SoundUtils.Initialize()
    
    -- Configurar volumes para combate
    SoundUtils.SetVolumeRange(-40, 0)
    SoundUtils.SetFadeSettings(2.0, 30)  -- Fade mais longo e suave para combate

    -- Registrar event handlers no core
    DeboCore.RegisterEventHandler("combat_start", Combat.OnCombatStart)
    DeboCore.RegisterEventHandler("combat_end", Combat.OnCombatEnd)
    DeboCore.RegisterEventHandler("attack_sound", Combat.OnAttackSound)

    -- Configurar estado inicial
    Combat.State.combat_start_time = nil
    Combat.State.total_damage_dealt = 0
    Combat.State.total_damage_taken = 0
end

-- Event Handlers
function Combat.OnCombatStart(enemy_name)
    if DeboCore.Player.is_fighting then
        DeboCore.Debug("COMBAT", "Combate já em andamento")
        return
    end

    enemy_name = enemy_name or "Desconhecido"
    DeboCore.Info("COMBAT", "Combate iniciado contra: " .. enemy_name)

    -- Atualizar estado global do player usando as funções do core
    DeboCore.UpdatePlayerAttributes({
        is_fighting = true,
        current_enemy = enemy_name
    })

    -- Atualizar estatísticas do módulo de combate
    Combat.State.combat_start_time = os.time()
    Combat.State.total_damage_dealt = 0
    Combat.State.total_damage_taken = 0

    -- Iniciar música de combate
    Combat.StartBattleMusic()
end

function Combat.OnCombatEnd(reason)
    if not DeboCore.Player.is_fighting then
        return
    end

    reason = reason or "Desconhecido"
    DeboCore.Info("COMBAT", "Combate finalizado: " .. reason)

    -- Calcular duração do combate
    local combat_duration = Combat.State.combat_start_time and (os.time() - Combat.State.combat_start_time) or 0
    
    if combat_duration > 0 then
        DeboCore.Info("COMBAT", string.format("Duração: %d segundos | Dano causado: %d | Dano recebido: %d", 
            combat_duration, Combat.State.total_damage_dealt, Combat.State.total_damage_taken))
    end

    -- Atualizar estado global do player usando as funções do core
    DeboCore.UpdatePlayerAttributes({
        is_fighting = false,
        current_enemy = nil
    })

    -- Limpar estatísticas do combate
    Combat.State.combat_start_time = nil
    Combat.State.total_damage_dealt = 0
    Combat.State.total_damage_taken = 0

    -- Parar música de combate
    Combat.StopBattleMusic()
end

function Combat.OnAttackSound(attack_type)
    Combat.PlayAttackSound(attack_type)
    Combat.State.last_attack_type = attack_type
end

-- Função para registrar dano causado pelo player
function Combat.RegisterDamageDealt(damage)
    if DeboCore.Player.is_fighting then
        Combat.State.total_damage_dealt = Combat.State.total_damage_dealt + damage
        DeboCore.Debug("COMBAT", "Dano causado: " .. damage .. " (Total: " .. Combat.State.total_damage_dealt .. ")")
    end
end

-- Função para registrar dano recebido pelo player
function Combat.RegisterDamageTaken(damage)
    if DeboCore.Player.is_fighting then
        Combat.State.total_damage_taken = Combat.State.total_damage_taken + damage
        DeboCore.Debug("COMBAT", "Dano recebido: " .. damage .. " (Total: " .. Combat.State.total_damage_taken .. ")")
    end
end

-- Função para extrair valor de dano das linhas de texto
function Combat.ExtractDamageFromLine(line)
    -- Procurar padrões como [123] ou [-45]
    local damage_positive = string.match(line, "%[(%d+)%]")
    local damage_negative = string.match(line, "%[%-(%d+)%]")
    
    if damage_positive then
        return tonumber(damage_positive)
    elseif damage_negative then
        return tonumber(damage_negative)
    end
    
    return nil
end

-- Funções de som
function Combat.PlayAttackSound(attack_type)
    local sound_folder = Combat.AttackTypes[attack_type]
    if not sound_folder then
        DeboCore.Warn("COMBAT", "Tipo de ataque desconhecido: " .. tostring(attack_type))
        return
    end

    local sound_path = Combat.Settings.sound_path .. sound_folder
    DeboCore.Debug("COMBAT", "Tocando som de ataque: " .. sound_path)

    -- Chamar plugin de som aleatório (se disponível)
    local args = string.format("0,%s,n,0", sound_path)
    local result = CallPlugin("461479af5d149307e69e305f", "PlayRandomSound", args)

    if result ~= 0 then
        DeboCore.Warn("COMBAT", "Erro ao reproduzir som para: " .. attack_type)
    end
end

function Combat.StartBattleMusic()
    if not DeboCore.Settings.music_enabled then
        DeboCore.Debug("COMBAT", "Música desabilitada")
        return
    end

    -- Verificar se já está tocando
    if GetSoundStatus and GetSoundStatus(Combat.Settings.music_channel) > 0 then
        DeboCore.Debug("COMBAT", "Música de combate já está tocando")
        return
    end

    DeboCore.Debug("COMBAT", "Iniciando música de combate")
    DeboCore.Debug("COMBAT", "Arquivo de música: " .. Combat.Settings.music_path)
    DeboCore.Debug("COMBAT", "Canal: " .. Combat.Settings.music_channel)

    if PlaySound then
        -- Iniciar música no volume mínimo
        local result = PlaySound(Combat.Settings.music_channel, Combat.Settings.music_path, true, -40)
        DeboCore.Debug("COMBAT", "PlaySound resultado: " .. tostring(result))
        
        -- Verificar se conseguiu iniciar
        if GetSoundStatus then
            local status = GetSoundStatus(Combat.Settings.music_channel)
            DeboCore.Debug("COMBAT", "Status após PlaySound: " .. status)
        end
        
        -- Fazer fade in suave usando SoundUtils
        SoundUtils.FadeIn(Combat.Settings.music_channel, -40, Combat.Settings.combat_volume, 3.0, 40)
    else
        DeboCore.Warn("COMBAT", "PlaySound não está disponível")
    end
end

function Combat.StopBattleMusic()
    if GetSoundStatus and GetSoundStatus(Combat.Settings.music_channel) > 0 then
        DeboCore.Debug("COMBAT", "Parando música de combate")
        
        -- Fazer fade out suave usando SoundUtils antes de parar
        SoundUtils.FadeOut(Combat.Settings.music_channel, Combat.Settings.combat_volume, -40, 2.0, 30)
    end
end

-- Funções de análise de texto para triggers
function Combat.AnalyzePrompt(line)
    -- Verificar se é prompt de combate
    if string.match(line, "^<.*%%.*>$") then
        if not DeboCore.Player.is_fighting then
            DeboCore.TriggerEvent("combat_start")
        end
    else
        if DeboCore.Player.is_fighting then
            DeboCore.TriggerEvent("combat_end", "Prompt normal detectado")
        end
    end
end

function Combat.AnalyzeFightPrompt(line, wildcards)
    local enemy_name = wildcards and wildcards.enemy or "Desconhecido"
    DeboCore.TriggerEvent("combat_start", enemy_name)
end

function Combat.AnalyzeEnemyDeath(line)
    DeboCore.TriggerEvent("combat_end", "Inimigo morreu")
end

function Combat.AnalyzeEnemyFled(line)
    DeboCore.TriggerEvent("combat_end", "Inimigo fugiu")
end

function Combat.AnalyzePlayerDeath(line)
    DeboCore.TriggerEvent("combat_end", "Jogador morreu")
end

function Combat.AnalyzePlayerFled(line)
    DeboCore.TriggerEvent("combat_end", "Jogador fugiu")
end

-- Função principal para processar triggers de combate
function Combat.ProcessTrigger(trigger_name, line, wildcards)
    DeboCore.Debug("COMBAT", "Processando trigger: " .. trigger_name)

    if trigger_name == "Prompt" then
        Combat.AnalyzePrompt(line)
    elseif trigger_name == "Fight_Prompt" then
        Combat.AnalyzeFightPrompt(line, wildcards)
    elseif trigger_name == "Inimigo_Morreu" then
        Combat.AnalyzeEnemyDeath(line)
    elseif trigger_name == "Inimigo_Fugiu" then
        Combat.AnalyzeEnemyFled(line)
    elseif trigger_name == "Jogador_Morreu" then
        Combat.AnalyzePlayerDeath(line)
    elseif trigger_name == "Jogador_Fugiu" then
        Combat.AnalyzePlayerFled(line)
    elseif string.match(trigger_name, "^TYPE_") then
        -- É um trigger de ataque
        DeboCore.TriggerEvent("attack_sound", trigger_name)
        
        -- Se é trigger de dano causado, extrair valor
        if trigger_name ~= "TYPE_MISS" and trigger_name ~= "TYPE_PARRY" and trigger_name ~= "TYPE_SHIELD" then
            local damage = Combat.ExtractDamageFromLine(line)
            if damage and damage > 0 then
                Combat.RegisterDamageDealt(damage)
            end
        end
        
        -- Se é trigger de dano recebido
        if trigger_name == "TYPE_HURT" then
            local damage = Combat.ExtractDamageFromLine(line)
            if damage and damage > 0 then
                Combat.RegisterDamageTaken(damage)
            end
        end
    end
end

-- Comandos do módulo
function Combat.Commands()
    return {
        ["combat stop"] = Combat.StopCombat,
        ["combat debug"] = Combat.ToggleDebug,
        ["combat status"] = Combat.ShowStatus,
        ["combat reset"] = Combat.ResetStats,
        ["combat test"] = Combat.TestSound,
        ["combat music test"] = Combat.TestMusic,
        ["combat music stop"] = Combat.ForceStopBattleMusic,
        ["combat music status"] = Combat.ShowMusicStatus
    }
end

function Combat.StopCombat()
    DeboCore.TriggerEvent("combat_end", "Comando manual")
    DeboCore.Info("COMBAT", "Combate parado manualmente")
end

function Combat.ToggleDebug()
    DeboCore.Settings.debug = not DeboCore.Settings.debug
    local status = DeboCore.Settings.debug and "ativado" or "desativado"
    DeboCore.Info("COMBAT", "Debug " .. status)
end

function Combat.ShowStatus()
    local status = DeboCore.Player.is_fighting and "EM COMBATE" or "Fora de combate"
    local enemy = DeboCore.Player.current_enemy or "Nenhum"
    
    DeboCore.Info("COMBAT", "=== STATUS DE COMBATE ===")
    DeboCore.Info("COMBAT", "Status: " .. status)
    DeboCore.Info("COMBAT", "Inimigo: " .. enemy)
    
    if DeboCore.Player.is_fighting and Combat.State.combat_start_time then
        local duration = os.time() - Combat.State.combat_start_time
        DeboCore.Info("COMBAT", "Duração atual: " .. duration .. " segundos")
        DeboCore.Info("COMBAT", "Dano causado: " .. Combat.State.total_damage_dealt)
        DeboCore.Info("COMBAT", "Dano recebido: " .. Combat.State.total_damage_taken)
    end
    
    DeboCore.Info("COMBAT", "Último ataque: " .. (Combat.State.last_attack_type or "Nenhum"))
end

function Combat.ResetStats()
    Combat.State.total_damage_dealt = 0
    Combat.State.total_damage_taken = 0
    Combat.State.last_attack_type = nil
    DeboCore.Info("COMBAT", "Estatísticas de combate resetadas")
end

function Combat.TestSound()
    DeboCore.Info("COMBAT", "Testando som de ataque TYPE_HIT...")
    Combat.PlayAttackSound("TYPE_HIT")
end

function Combat.TestMusic()
    DeboCore.Info("COMBAT", "Testando música de combate...")
    Combat.StartBattleMusic()
end

-- Função para parar imediatamente toda música de combate
function Combat.ForceStopBattleMusic()
    DeboCore.Debug("COMBAT", "Parando música de combate imediatamente")
    
    -- Parar qualquer fade em andamento
    SoundUtils.StopFade(Combat.Settings.music_channel)
    
    -- Parar o som imediatamente
    if StopSound then
        StopSound(Combat.Settings.music_channel)
    end
end

-- Função para ajustar volume da música durante combate
function Combat.SetBattleMusicVolume(volume)
    if GetSoundStatus and GetSoundStatus(Combat.Settings.music_channel) > 0 then
        DeboCore.Debug("COMBAT", "Ajustando volume da música para: " .. volume)
        Combat.Settings.combat_volume = volume
        
        if PlaySound then
            PlaySound(Combat.Settings.music_channel, "", true, volume)
        end
    end
end

-- Função para verificar se música de combate está tocando
function Combat.IsBattleMusicPlaying()
    if GetSoundStatus then
        return GetSoundStatus(Combat.Settings.music_channel) > 0
    end
    return false
end

-- Função para mostrar status da música
function Combat.ShowMusicStatus()
    local music_enabled = DeboCore.Settings.music_enabled and "ativada" or "desativada"
    local music_playing = Combat.IsBattleMusicPlaying() and "tocando" or "parada"
    local is_fading = SoundUtils.IsFading(Combat.Settings.music_channel) and "em fade" or "sem fade"
    
    DeboCore.Info("COMBAT", "=== STATUS DA MÚSICA ===")
    DeboCore.Info("COMBAT", "Música: " .. music_enabled)
    DeboCore.Info("COMBAT", "Estado: " .. music_playing)
    DeboCore.Info("COMBAT", "Fade: " .. is_fading)
    DeboCore.Info("COMBAT", "Canal: " .. Combat.Settings.music_channel)
    DeboCore.Info("COMBAT", "Volume: " .. Combat.Settings.combat_volume .. " dB")
    
    if GetSoundStatus then
        local status = GetSoundStatus(Combat.Settings.music_channel)
        DeboCore.Info("COMBAT", "Status do buffer: " .. status)
    end
end

return Combat
