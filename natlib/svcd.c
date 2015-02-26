#define SVCD_SYMBOLS \
	{ LSTRKEY( "svcd_add_service"), LFUNCVAL ( svcd_add_service )}, \
    { LSTRKEY( "svcd_add_attribute"), LFUNCVAL ( svcd_add_attribute )},

// Lua: storm.n.svcd_add_service ( svcd_id )
// Add a new service to the service daemon
// this must be called before SVCD.advertise()
static int svcd_add_service( lua_State *L ) {

    //TODO: Garbage collection?

    lua_getglobal(L, "SVCD");

    lua_pushstring(L, "blsmap");
    lua_gettable(L, 2);
    lua_pushvalue(L, 1); //svc_id @ index 4
    lua_pushlightfunction(L, libstorm_bl_addservice);
    lua_pushvalue(L, 1); //svc_id @ index 6
    lua_call(L, 1, 1);
    lua_settable(L, 3);

    lua_pushstring(L, "blamap");
    lua_gettable(L, 2);
    lua_pushvalue(L, 1); //svc_id @ index 5
    lua_newtable(L);
    lua_settable(L, 4);

    lua_pushstring(L, "manifest");
    lua_gettable(L, 2);
    lua_pushvalue(L, 1); //svc_id @ index 6
    lua_newtable(L);
    lua_settable(L, 5);

    lua_pushstring(L, "manifest_map");
    lua_gettable(L, 2);
    lua_pushvalue(L, 1); //svc_id @ index 7
    lua_newtable(L);
    lua_settable(L, 6);

    return 0;
}

// Lua: storm.n.svcd_add_attribute ( svc_id, attr_id, write_fn )
// Add a new attribute to a service in the service daemon
static int svcd_add_attribute( lua_State *L ) {

    lua_getglobal(L, "SVCD"); //Index 4

    lua_pushstring(L, "blsmap"); //Index 5
    lua_gettable(L, 4);

    lua_pushstring(L, "blamap"); //Index 6
    lua_gettable(L, 4);
    lua_pushvalue(L, 1); //svc_id @ Index 7
    lua_gettable(L, 6);
    lua_pushvalue(L, 2); //attr_id @ Index 8 - key

    lua_pushlightfunction(L, libstorm_bl_addcharacteristic); //Index 9
    lua_pushvalue(L, 1); //svc_id @ Index 10
    lua_gettable(L, 5);
    lua_pushvalue(L, 2); //attr_id @ Index 11
    lua_pushvalue(L, 3); //wrtie_fn @ Index 12
    lua_call(L, 3, 1); //Returns at Index 9 - value

    lua_settable(L, 7); //Remove index 8, 9

    lua_pushstring(L, "manifest"); //Index 8
    lua_gettable(L, 4);
    lua_pushvalue(L, 1); //svc_id @ Index 9
    lua_gettable(L, 8);
    int n = luaL_getn(L, 9);
    lua_pushvalue(L, 2); //attr_id @ Index 10
    lua_rawseti(L, 9, n+1); //Index back to 9

    lua_pushstring(L, "manifest_map"); // Index 10
    lua_gettable(L, 4);
    lua_pushvalue(L, 1); //svc_id @ Index 11
    lua_gettable(L, 10);
    lua_pushvalue(L, 2); //attr_id @ Index 12
    lua_pushvalue(L, 3); // write_fn @ Index 13
    lua_settable(L, 11); //Index back to 11

    return 0;
}