script_authors("Memes & Hatori")
script_description("")
script_version(03082022)

local encoding = require 'encoding' -- ���������� ��� ���������� �������� ������� ����
encoding.default = 'CP1251'
u8 = encoding.UTF8
local sampev = require 'lib.samp.events' -- ���������� ��� ���� �������� ������ �� ������
local effil = require 'effil' -- ��� ������������ ��������
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
   while not isSampAvailable() do wait(0) end
end

function sampev.onServerMessage(color, text)
    local idstr = '%[(%d+)%] (.+) %| �������: (%d+) %| UID: (%d+)' -- [00:39:52] [1] Cursed_Gitlerov | �������: 0 | UID: -1 | packetloss: 0.00 (��������� �������)
    if text:find(idstr) and check then
        check=false
        local playerId, playerName, playerlvl, playerUID = text:match(idstr)
        data['embeds'][1]['description'] =data['embeds'][1]['description']..'�����: '..playerName..' ['..playerId..']\n�������: '..playerlvl..'\nUID: '..playerUID..''
        asyncHttpRequest('POST', url, {headers = {['content-type'] = 'application/json'}, data = u8(encodeJson(data))})
        return false
    end
    
    local house = '(.+) (.+)%[(%d+)%] ����� ��� ID: (%d+) �� ���. ���� �� (%d+).(%d+) ms!'
    if text:find(house) then
      local nothing,playerName, playerId, houseId, timeslet, timesletms  = text:match(house)  -- [02:00:08] Liniks_Burton [3] ����� ��� ID: 481 �� ���. ���� �� 1.19 ms! (old)
      playerId=tonumber(playerId)
      data['embeds'][1]['description'] = '��� ���������: ��� ['..houseId..'] ('..timeslet.. '.' ..timesletms..'ms)\n'
      data['embeds'][1]['color']=0x9b59b6
      send_rpc_command('/id '..playerId)
      check=true
      return
    end
    
    local biz = '(.+) (.+)%[(%d+)%] ����� ������ ID: (%d+) �� ���. ���� �� (%d+).(%d+) ms!'
    if text:find(biz) then
      local nothing,playerName, playerId, bizId, timeslet, timesletms  = text:match(biz)  -- [04:00:24] Cristiano_Depressed [179] ����� ������ ID: 93 �� ���. ���� �� 2.84 ms! (old)
      playerId=tonumber(playerId)
      data['embeds'][1]['description'] = '��� ���������: ������ ['..bizId..'] ('..timeslet.. '.' ..timesletms..'ms)\n'
      data['embeds'][1]['color']=0x9b59b6
      send_rpc_command('/id '..playerId)
      check=true
   
      return
    end
    
    local car = '(.+) (.+)%[(%d+)%] ����� ��������� �� ���� %((.+)%), ����: (.+), ���������: (.+)'
    if text:find(car) then
      local nothing,playerName, playerId, carname, price, salon  = text:match(car) -- [A] Player[777] ����� ��������� �� ���� (VAZ 2108), ����: $100000, ���������: ������.
      playerId=tonumber(playerId)
      data['embeds'][1]['description'] = '��� ���������:\n��������� '..carname..' ['..price..']  '..salon
      data['embeds'][1]['color']=0xfa0a3e
      send_rpc_command('/id '..playerId)
      check=true
   return
    end
    -- 

end
 -- 
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
   -- ���� ������ ��� ������� ��������� ������ � ������.
   if not resolve then resolve = function() end end
   if not reject then reject = function() end end
   -- �������� ���������� ������
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
