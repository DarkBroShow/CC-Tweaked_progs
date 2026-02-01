-- ИМЯ ФАЙЛА С ТЕКСТОМ
local FILENAME = "erwin/erwin.txt"

-- Подключаем чат-бокс
local chat = peripheral.wrap("right")  -- поменяй "right", если чат-бокс в другом слоте
if not chat then
  error("Chat Box not found on 'right'")
end

-- Читаем все строки из файла в таблицу
local lines = {}
do
  local h, err = fs.open(FILENAME, "r")
  if not h then
    error("Cannot open file '" .. FILENAME .. "': " .. (err or "unknown error"))
  end

  while true do
    local line = h.readLine()
    if not line then break end
    if line ~= "" then
      table.insert(lines, line)
    end
  end

  h.close()
end

if #lines == 0 then
  error("File '" .. FILENAME .. "' is empty or has only empty lines")
end

-- Основной цикл: ходим по строкам по кругу
local index = 1

while true do
  local text = lines[index]

  -- message, prefix, brackets, bracketColor
  chat.sendMessage(text, "EbenGrad", "[]", "&a")

  -- следующий индекс по кругу
  index = index + 1
  if index > #lines then
    index = 1
  end

  -- задержка между сообщениями (в секундах)
  sleep(900)
end
