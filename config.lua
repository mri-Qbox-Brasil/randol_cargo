return {
    Debug = false,
    Fuel = {
        enable = true, -- I use ox_fuel so I set this to false and use statebag to set the fuel
        script = 'cdn-fuel',
    },
    Ped = 'mp_m_weapexp_01',
    PedCoords = vec4(-413.96, 6171.53, 30.48, 320.39),
    VehicleSpawn = vec4(-411.37, 6175.33, 31.48, 228.09),
    SpawnInVeh = false,
    DeliveryInfo = { 
        title = 'Transporte de carga', 
        msg = 'Entregue a carga para o local definido.', 
        sec = 3, 
        audioName = 'Boss_Message_Orange', audioRef = 'GTAO_Boss_Goons_FM_Soundset'
    },
    ReturnInfo = { 
        title = 'Transporte completo', 
        msg = 'Volte ao armazém para ser pago.', 
        sec = 7, 
        audioName = 'Mission_Pass_Notify', audioRef = 'DLC_HEISTS_GENERAL_FRONTEND_SOUNDS'
    },
    talkNPC = true, -- true = use talkNPC and overrude all modes below
    Target = false, -- true = use target | false = ox lib zones [E] to interact.
}
