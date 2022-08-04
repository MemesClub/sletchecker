require "lib.moonloader"

script_authors("Memes & Hatori")
script_description("Версия 060822")
script_version("06.08.2022")
script_properties('Work-in-pause')
script_url("https://github.com/MemesClub/sletchecker")

function update()
   local raw = 'https://raw.githubusercontent.com/MemesClub/sletchecker/main/version.json'
   local dlstatus = require('moonloader').download_status
   local requests = require('requests')
   local f = {}
   function f:getLastVersion()
       local response = requests.get(raw)
       if response.status_code == 200 then
           return decodeJson(response.text)['last']
       else
           return 'UNKNOWN'
       end
   end
   function f:download()
       local response = requests.get(raw)
       if response.status_code == 200 then
           downloadUrlToFile(decodeJson(response.text)['url'], thisScript().path, function (id, status, p1, p2)
               print('Скачиваю '..decodeJson(response.text)['url']..' в '..thisScript().path)
               if status == dlstatus.STATUSEX_ENDDOWNLOAD then
                   sampAddChatMessage('Скрипт обновлен, перезагрузка...', -1)
                   thisScript():reload()
               end
           end)
       else
           sampAddChatMessage('Ошибка, невозможно установить обновление, код: '..response.status_code, -1)
       end
   end
   return f
end

local idstr = '%[(%d+)%] (.+) %| Уровень: (%d+) %| UID: (%d+)' -- [00:39:52] [1] Cursed_Gitlerov | Уровень: 0 | UID: -1 | packetloss: 0.00 (мобильный лаунчер)
local house = '(.+) (.+)%[(%d+)%] купил дом ID: (%d+) по гос. цене за (%d+).(%d+) ms!'
local biz = '(.+) (.+)%[(%d+)%] купил бизнес ID: (%d+) по гос. цене за (%d+).(%d+) ms!'
local car = '(.+) (.+)%[(%d+)%] купил транспорт по госу %((.+)%), цена: (.+), автосалон: (.+)'

local encoding = require 'encoding' -- подключаем для корректной отправки русских букв
encoding.default = 'CP1251'
u8 = encoding.UTF8
local sampev = require 'lib.samp.events' -- подключаем для хука отправки ответа на диалог
local effil = require 'effil' -- для ассинхронных запросов
local check= false
local url = 'https://discord.com/api/webhooks/1003780941291991090/JdnaUneuCFtQpxGbW2UUbfCqfUjipDjJ0zIMUnN4B1CFUBYCYyjVEsVxR1Wk_6Wis7SG'
local data = {
    ['username'] = '',
    ['avatar_url'] = '',
    ['content'] = '',
    ['embeds'] = {
        {
            ['title'] = '',
            ['description'] = '',
            ['color'] = ''
        }
    }
}

function main()
   if not isSampfuncsLoaded() or not isSampLoaded() then
      return
    end
    while not isSampAvailable() do
      wait(100)
    end
  
    -- вырежи тут, если хочешь отключить проверку обновлений
    if autoupdate_loaded and enable_autoupdate and Update then
      pcall(Update.check, Update.json_url, Update.prefix, Update.url)
    end

_, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
nickname = sampGetPlayerNickname(id)
data['username'] = nickname
end

function sampev.onServerMessage(color, text)
    if text:find(idstr) and check then
        check=false
        local playerId, playerName, playerlvl, playerUID = text:match(idstr)
        data['embeds'][1]['description'] =data['embeds'][1]['description']..'Игрок: '..playerName..' ['..playerId..']\nУровень: '..playerlvl..'\nUID: '..playerUID..''
        asyncHttpRequest('POST', url, {headers = {['content-type'] = 'application/json'}, data = u8(encodeJson(data))})
        return false
    end
    
    if text:find(house) then
      local nothing,playerName, playerId, houseId, timeslet, timesletms  = text:match(house)  -- [02:00:08] Liniks_Burton [3] купил дом ID: 481 по гос. цене за 1.19 ms! (old)
      playerId=tonumber(playerId)
      data['embeds'][1]['description'] = 'Тип имущества: Дом ['..houseId..'] ('..timeslet.. '.' ..timesletms..'ms)\n'
      data['embeds'][1]['color']=0x9b59b6
      send_rpc_command('/id '..playerId)
      check=true
      return
    end
    
    if text:find(biz) then
      local nothing,playerName, playerId, bizId, timeslet, timesletms  = text:match(biz)  -- [04:00:24] Cristiano_Depressed [179] купил бизнес ID: 93 по гос. цене за 2.84 ms! (old)
      playerId=tonumber(playerId)
      data['embeds'][1]['description'] = 'Тип имущества: Бизнес ['..bizId..'] ('..timeslet.. '.' ..timesletms..'ms)\n'
      data['embeds'][1]['color']=0x9b59b6
      send_rpc_command('/id '..playerId)
      check=true
      return
    end
    
    if text:find(car) then
      local nothing,playerName, playerId, carname, price, salon  = text:match(car) -- [A] Player[777] купил транспорт по госу (VAZ 2108), цена: $100000, автосалон: Эконом.
      playerId=tonumber(playerId)
      data['embeds'][1]['description'] = 'Тип имущества:\nТранспорт '..carname..' ['..price..']  '..salon
      data['embeds'][1]['color']=0xfa0a3e
      send_rpc_command('/id '..playerId)
      check=true
      return
    end
end

function asyncHttpRequest(method, url, args, resolve, reject)
   local request_thread = effil.thread(function (method, url, args)
      local requests = require 'requests'
      local result, response = pcall(requests.request, method, url, args)
      if result then
         response.json, response.xml = nil, nil
         return true, response
      else
         return false, response
      end
   end)(method, url, args)
   -- Если запрос без функций обработки ответа и ошибок.
   if not resolve then resolve = function() end end
   if not reject then reject = function() end end
   -- Проверка выполнения потока
   lua_thread.create(function()
      local runner = request_thread
      while true do
         local status, err = runner:status()
         if not err then
            if status == 'completed' then
               local result, response = runner:get()
               if result then
                  resolve(response)
               else
                  reject(response)
               end
               return
            elseif status == 'canceled' then
               return reject(status)
            end
         else
            return reject(err)
         end
         wait(0)
      end
   end)
end

function send_rpc_command(text)
    local bs = raknetNewBitStream()
    local rn = require 'samp.raknet'
    raknetBitStreamWriteInt32(bs, #text)
    raknetBitStreamWriteString(bs, text)
    raknetSendRpc(rn.RPC.SERVERCOMMAND, bs)
    raknetDeleteBitStream(bs)
end
