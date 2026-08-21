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

-- Основной скрипт логирования
local log_file = "chunk_loader_log.txt"
local check_interval = 5 -- секунд между проверками
local max_idle_checks = 3 -- сколько раз подряд чанки должны быть неактивны, чтобы считать, что они выгрузились

local function log_message(real_time, game_time, status)
    local file = fs.open(log_file, "a")
    file.writeLine(string.format("[%s] [%s] %s", real_time, game_time, status))
    file.close()
end

-- Основной цикл
local function start_logging()
    -- Создаём файл с заголовком
    local file = fs.open(log_file, "w")
    file.writeLine("=== Лог загрузки чанков ===")
    file.writeLine(string.format("Старт: [%s] [%s]", time.real(), time.ingame()))
    file.writeLine("---")
    file.close()
    
    local idle_count = 0
    local was_loaded = false
    
    print("Logging starting...")
    print("file: " .. log_file)
    print("Check interval: " .. check_interval .. " seconds.")
    print("Press Ctrl+T for cancel")
    print("---")
    
    while true do
        local real_time = time.real()
        local game_time = time.ingame()
        local loaded = #peripheral.getNames() > 0
        
        if loaded then
            if not was_loaded then
                log_message(real_time, game_time, "ЧАНК ЗАГРУЖЕН")
                print(string.format("[%s] [%s] ✅ Chunk loaded", real_time, game_time))
            else
                -- Каждые 5 записей пишем "сердцебиение"
                if math.random(1, 5) == 1 then
                    log_message(real_time, game_time, "heartbeat")
                end
            end
            idle_count = 0
            was_loaded = true
        else
            if was_loaded then
                log_message(real_time, game_time, "ЧАНК ВЫГРУЖЕН!")
                print(string.format("[%s] [%s] ❌ Chunk unloaded!", real_time, game_time))
                was_loaded = false
            end
            
            idle_count = idle_count + 1
            if idle_count >= max_idle_checks then
                -- Чанк не загружается слишком долго, завершаем логирование
                log_message(real_time, game_time, "STOP: Chunk unloaded " .. max_idle_checks .. " check in row")
                print(string.format("---\n⏹️ Stopping! Chunk unloaded %d checks in row", max_idle_checks))
                print("Stop time: " .. real_time)
                print("Ingame time: " .. game_time)
                break
            end
        end
        
        sleep(check_interval)
    end
    
    -- Записываем финальную метку
    local file = fs.open(log_file, "a")
    file.writeLine("---")
    file.writeLine(string.format("СТОП: [%s] [%s]", time.real(), time.ingame()))
    file.writeLine("=== Конец лога ===")
    file.close()
    
    print("---")
    print("Log saved in: " .. log_file)
end

-- Запуск
start_logging()