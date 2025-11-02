-- debo.core.lua
-- Core functionality for all Debo plugins

local DeboCore = {}
DeboCore.__index = DeboCore

-- Versão do core
DeboCore.VERSION = "1.0.0"

-- Estado global do jogador
DeboCore.Player = {
    -- Estados dinâmicos
    is_fighting = false,
    can_move = true,
    current_enemy = nil,
    current_area = nil,
    
    -- Informações básicas do personagem
    name = "N/A",
    class = "N/A",
    race = "N/A",
    level = 1,
    reinc = 0,          -- Reencarnações
    age = 0,
    partner = "Ninguém",
    
    -- Estatísticas vitais
    health = 100,
    health_max = 100,
    mana = 100,
    mana_max = 100,
    move = 100,
    move_max = 100,
    
    -- Recursos
    gold = 0,
    bank_gold = 0,
    exp = 0,
    exp_next = 0,
    
    -- Necessidades básicas
    hunger = 24,
    hunger_max = 24,
    thirst = 24,
    thirst_max = 24,
    
    -- Alinhamento
    align = 0,
    
    -- Arena
    arena_wins = 0,
    arena_losses = 0,
    
    -- Estatísticas de jogo
    game_time_hours = 0,    -- Tempo total jogado em horas
    deaths = 0,
    deathtraps = 0,
    adventure_points = 0,
    
    -- Atributos primários
    strength = 10,
    wisdom = 10,
    constitution = 10,
    intelligence = 10,
    dexterity = 10,
    charisma = 10,
    
    -- Atributos de combate
    hit_bonus = 0,      -- Bônus de acerto
    damage_bonus = 0,   -- Bônus de dano
    armor_class = 0     -- Classe de armadura
}

-- Configurações globais
DeboCore.Settings = {
    debug = false,
    sound_enabled = true,
    music_enabled = true,
    volume = -20
}

-- Sistema de eventos
DeboCore.EventHandlers = {}

-- Função para registrar handlers de eventos
function DeboCore.RegisterEventHandler(event_name, handler_func)
    if not DeboCore.EventHandlers[event_name] then
        DeboCore.EventHandlers[event_name] = {}
    end
    table.insert(DeboCore.EventHandlers[event_name], handler_func)
end

-- Função para disparar eventos
function DeboCore.TriggerEvent(event_name, ...)
    if DeboCore.EventHandlers[event_name] then
        for _, handler in ipairs(DeboCore.EventHandlers[event_name]) do
            handler(...)
        end
    end
end

-- Sistema de logging/debug
function DeboCore.Log(level, module, message)
    if not DeboCore.Settings.debug and level == "DEBUG" then
        return
    end
    
    local timestamp = os.date("%H:%M:%S")
    local log_message = string.format("[%s] [%s] [%s] %s", timestamp, level, module, message)
    
    if level == "ERROR" then
        ColourNote("red", "black", log_message)
    elseif level == "WARN" then
        ColourNote("yellow", "black", log_message)
    elseif level == "INFO" then
        ColourNote("cyan", "black", log_message)
    else
        ColourNote("white", "black", log_message)
    end
end

-- Funções de conveniência para logging
function DeboCore.Debug(module, message)
    DeboCore.Log("DEBUG", module, message)
end

function DeboCore.Info(module, message)
    DeboCore.Log("INFO", module, message)
end

function DeboCore.Warn(module, message)
    DeboCore.Log("WARN", module, message)
end

function DeboCore.Error(module, message)
    DeboCore.Log("ERROR", module, message)
end

-- Função para carregar configurações
function DeboCore.LoadSettings()
    local music_setting = GetVariable("music")
    if music_setting == "off" then
        DeboCore.Settings.music_enabled = false
    end
    
    local debug_setting = GetVariable("debug")
    if debug_setting == "on" then
        DeboCore.Settings.debug = true
    end
end

-- Função para salvar configurações
function DeboCore.SaveSettings()
    SetVariable("music", DeboCore.Settings.music_enabled and "on" or "off")
    SetVariable("debug", DeboCore.Settings.debug and "on" or "off")
end

-- Funções para gerenciar atributos do Player
function DeboCore.UpdatePlayerAttribute(attribute, value)
    if DeboCore.Player[attribute] ~= nil then
        local old_value = DeboCore.Player[attribute]
        DeboCore.Player[attribute] = value
        
        -- Disparar evento quando atributo muda
        if old_value ~= value then
            DeboCore.TriggerEvent("player_attribute_changed", attribute, value, old_value)
            DeboCore.Debug("CORE", string.format("Player.%s: %s -> %s", attribute, tostring(old_value), tostring(value)))
        end
    else
        DeboCore.Warn("CORE", "Atributo desconhecido: " .. tostring(attribute))
    end
end

-- Função para atualizar múltiplos atributos de uma vez
function DeboCore.UpdatePlayerAttributes(attributes_table)
    for attribute, value in pairs(attributes_table) do
        DeboCore.UpdatePlayerAttribute(attribute, value)
    end
end

-- Função para obter atributo do player de forma segura
function DeboCore.GetPlayerAttribute(attribute, default_value)
    if DeboCore.Player[attribute] ~= nil then
        return DeboCore.Player[attribute]
    else
        DeboCore.Warn("CORE", "Atributo desconhecido: " .. tostring(attribute))
        return default_value
    end
end

-- Inicialização do core
function DeboCore.Initialize()
    DeboCore.LoadSettings()
    DeboCore.Info("CORE", "DeboCore v" .. DeboCore.VERSION .. " inicializado")
end

return DeboCore