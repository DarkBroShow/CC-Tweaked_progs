-- Функция работы со временем
local time = {
    real = function()
        return os.date("%H.%M.%S")
    end,
    ingame = function()
        local ingame = os.time("ingame")
        local hours = math.floor(ingame)
        local minutes = math.floor((ingame - hours) * 60)
        return string.format("%02d.%02d", hours, minutes)
    end
}









-- Использование:
print("Real Time: " .. time.real())
print("Game Time: " .. time.ingame())