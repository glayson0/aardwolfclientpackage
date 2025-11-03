-- sound_utils.lua
-- Módulo de utilitários de som para MUSHclient

require "wait"

local SoundUtils = {}
SoundUtils.__index = SoundUtils
SoundUtils.VERSION = "1.0.0"

-- Configurações padrão
SoundUtils.Settings = {
    max_volume = 0,
    min_volume = -40,
    fade_duration = 1.0,  -- Duração do fade em segundos
    fade_steps = 20       -- Número de passos para o fade
}

-- Estado interno
SoundUtils.State = {
    fade_control = {}  -- Tabela para controlar o estado de interrupção de cada buffer
}

-- Inicialização do módulo
function SoundUtils.Initialize()
    SoundUtils.State.fade_control = {}
    -- Opcional: log de inicialização se tiver DeboCore disponível
    if DeboCore and DeboCore.Info then
        DeboCore.Info("SOUND", "SoundUtils v" .. SoundUtils.VERSION .. " inicializado")
    end
end

-- Função para aumentar um som em loop suavemente
function SoundUtils.FadeIn(buffer, start_volume, final_volume, duration, steps)
    duration = duration or SoundUtils.Settings.fade_duration
    steps = steps or SoundUtils.Settings.fade_steps
    
    -- Debug
    if DeboCore and DeboCore.Debug then
        DeboCore.Debug("SOUND", string.format("FadeIn: buffer=%d, start=%d, final=%d, duration=%.1f", 
            buffer, start_volume or -40, final_volume or 0, duration))
    end
    
    SoundUtils.State.fade_control[buffer] = false
    
    wait.make(function()
        local max_volume = final_volume or SoundUtils.Settings.max_volume
        local min_volume = start_volume or SoundUtils.Settings.min_volume
        local current_volume = start_volume or min_volume
        
        for i = 0, steps do
            if SoundUtils.State.fade_control[buffer] then 
                return current_volume 
            end
            
            local t = i / steps
            -- Função de easing cubic para transição suave
            current_volume = min_volume + ((max_volume - min_volume) * (3*t*t - 2*t*t*t))
            
            if PlaySound then
                PlaySound(buffer, "", true, current_volume)
            end
            
            wait.time(duration / steps)
        end
        
        return current_volume
    end)
end

-- Função para diminuir um som suavemente
function SoundUtils.FadeOut(buffer, start_volume, final_volume, duration, steps)
    duration = duration or SoundUtils.Settings.fade_duration
    steps = steps or SoundUtils.Settings.fade_steps
    
    SoundUtils.State.fade_control[buffer] = false
    
    wait.make(function()
        local max_volume = start_volume or SoundUtils.Settings.max_volume
        local min_volume = final_volume or SoundUtils.Settings.min_volume
        local current_volume = start_volume or max_volume
        
        for i = 0, steps do
            if SoundUtils.State.fade_control[buffer] then
                return current_volume
            end
            
            local t = i / steps
            -- Função de easing cubic para transição suave
            current_volume = max_volume - ((max_volume - min_volume) * (3*t*t - 2*t*t*t))
            
            if PlaySound then
                PlaySound(buffer, "", false, current_volume)
            end
            
            wait.time(duration / steps)
        end
        
        if StopSound then
            StopSound(buffer)
        end
        
        return current_volume
    end)
end

-- Função para interromper o fade de um buffer específico
function SoundUtils.StopFade(buffer)
    SoundUtils.State.fade_control[buffer] = true
end

-- Função para verificar se um fade está em andamento
function SoundUtils.IsFading(buffer)
    return SoundUtils.State.fade_control[buffer] == false
end

-- Função para parar todos os fades
function SoundUtils.StopAllFades()
    for buffer, _ in pairs(SoundUtils.State.fade_control) do
        SoundUtils.State.fade_control[buffer] = true
    end
end

-- Função para configurar volumes padrão
function SoundUtils.SetVolumeRange(min_volume, max_volume)
    SoundUtils.Settings.min_volume = min_volume or SoundUtils.Settings.min_volume
    SoundUtils.Settings.max_volume = max_volume or SoundUtils.Settings.max_volume
end

-- Função para configurar parâmetros de fade
function SoundUtils.SetFadeSettings(duration, steps)
    SoundUtils.Settings.fade_duration = duration or SoundUtils.Settings.fade_duration
    SoundUtils.Settings.fade_steps = steps or SoundUtils.Settings.fade_steps
end

return SoundUtils