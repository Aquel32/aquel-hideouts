Apartments = {}
Apartments.Starting = false
Apartments.SpawnOffset = 125

Apartments.FirstPayment = 20
Apartments.Payment = 10

Apartments.Locations = {
    ["basement"] = {
        name = "basement",
        label = "Piwnica",
        coords = {
            enter = vector4(83.92, 190.65, 105.27, 127.13),
        },
        polyzoneBoxData = {
            heading = 123,
            minZ = 13.5,
            maxZ = 16.0,
            debug = false,
            length = 1,
            width = 3,
            distance = 2.0,
            created = false
        }
    },
    ["hangar"] = {
        name = "hangar",
        label = "Hangar",
        coords = {
            enter = vector4(106.6, 150.84, 105.55, 252.3),
        },
        polyzoneBoxData = {
            heading = 123,
            minZ = 13.5,
            maxZ = 16.0,
            debug = false,
            length = 1,
            width = 3,
            distance = 2.0,
            created = false
        }
    },
    ["jakieshujstwo"] = {
        name = "jakieshujstwo",
        label = "jakieshujstwo",
        coords = {
            enter = vector4(53.3, 160.55, 104.7, 116.27),
        },
        polyzoneBoxData = {
            heading = 123,
            minZ = 13.5,
            maxZ = 16.0,
            debug = false,
            length = 1,
            width = 3,
            distance = 2.0,
            created = false
        }
    },
    ["sezamkowa"] = {
        name = "sezamkowa",
        label = "Ulica Sezamkowa",
        coords = {
            enter = vector4(-182.76, 220.01, 88.82, 11.61),
        },
        polyzoneBoxData = {
            heading = 11.61,
            minZ = 11.5,
            maxZ = 12.0,
            debug = false,
            length = 1,
            width = 3,
            distance = 2.0,
            created = false
        }
    },
}

Apartments.WarehouseProps = {
    {
        name = "stash",
        modelHash = "p_v_43_safe_s",
        offset = vector3(-2.4, 4, 0),
        rx = 0.000, 
        ry = 0.000, 
        rz = 0.000
    },
    {
        name = "clothes",
        modelHash = "p_cs_locker_01_s",
        offset = vector3(-6, 4, 0),
        rx = 0.000, 
        ry = 0.000, 
        rz = 0.000
    },
    {
        name = "laptop",
        modelHash = "prop_laptop_01a",
        offset = vector3(-1.1, 3.8, 0.8),
        rx = 0.000, 
        ry = 0.000, 
        rz = 00.000
    },
    {
        name = "clothes2",
        modelHash = "p_cs_locker_01_s",
        offset = vector3(-6.5, 4, 0),
        rx = 0.000, 
        ry = 0.000, 
        rz = 0.000
    },
    {
        name = "tv",
        modelHash = "prop_tv_flat_01",
        offset = vector3(9.114137268066, 0.08510742188, 1.5),
        rx = 0.000, 
        ry = 0.000, 
        rz = -88.653
    },
    {
        name = "kanapa",
        modelHash = "prop_couch_lg_06",
        offset = vector3(5.5, 1.5, 0),
        rx = 0.000, 
        ry = 0.000, 
        rz = 55.500
    },
    {
        name = "fotel",
        modelHash = "prop_couch_sm_06",
        offset = vector3(5.5, -1.5, 0),
        rx = 0.000, 
        ry = 0.000, 
        rz = 135.500
    },
    {
        name = "stolik",
        modelHash = "prop_t_coffe_table_02",
        offset = vector3(6.8, 0, 0),
        rx = 0.000, 
        ry = 0.000, 
        rz = 90.000
    },
    {
        name = "lampa1",
        modelHash = "prop_wall_light_05c",
        offset = vector3(6.5, 0, 3.8),
        rx = 0.000, 
        ry = 0.000, 
        rz = 90.000
    },
    {
        name = "lampa2",
        modelHash = "prop_wall_light_05c",
        offset = vector3(0, 0, 3.8),
        rx = 0.000, 
        ry = 0.000, 
        rz = 90.000
    },
    {
        name = "lampa3",
        modelHash = "prop_wall_light_05c",
        offset = vector3(-6.5, 0, 3.8),
        rx = 0.000, 
        ry = 0.000, 
        rz = 90.000
    },
    {
        name = "lozko",
        modelHash = "prop_wait_bench_01",
        offset = vector3(0, -3.65, 0),
        rx = 0.000, 
        ry = 0.000, 
        rz = 0.00
    }, 
    {
        name = "lozko2",
        modelHash = "prop_wait_bench_01",
        offset = vector3(0, -2.77, 0),
        rx = 0.000, 
        ry = 0.000, 
        rz = 0.00
    },
    {
        name = "solikkolosafe",
        modelHash = "prop_table_04",
        offset = vector3(-1.1, 3.9, 0),
        rx = 0.000, 
        ry = 0.000, 
        rz = 0.000
    },
    {
        name = "tablicaplanowania",
        modelHash = "p_planning_board_01",
        offset = vector3(-8, -2.9, 0),
        rx = 0.000, 
        ry = 0.000, 
        rz = 140.000
    },
}
