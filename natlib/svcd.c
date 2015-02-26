#define SVCD_SYMBOLS \
	{ LSTRKEY( "svcd_add_service"), LFUNCVAL ( svcd_add_service )}, \
    { LSTRKEY( "svcd_add_attribute"), LFUNCVAL ( svcd_add_attribute )},

// Lua: storm.n.svcd_add_service ( svcd_id )
// Add a new service to the service daemon
// this must be called before SVCD.advertise()
static int svcd_add_service( lua_State *L ) {

    //TODO: Garbage collection?
    //Get param 1 from top of stack
    char * svc_id = (char *) luaL_checkstring(L, 1);

    lua_getglobal(L, "SVCD");

    lua_pushstring(L, "blsmap");
    lua_gettable(L, 2);
    lua_pushstring(L, svc_id);
    lua_pushlightfunction(L, libstorm_bl_addservice);
    lua_pushstring(L, svc_id);
    lua_call(L, 1, 1);
    lua_settable(L, 3);

    lua_pushstring(L, "blamap");
    lua_gettable(L, 2);
    lua_pushstring(L, svc_id);
    lua_newtable(L);
    lua_settable(L, 3);

    lua_pushstring(L, "manifest");
    lua_gettable(L, 2);
    lua_pushstring(L, svc_id);
    lua_newtable(L);
    lua_settable(L, 3);

    lua_pushstring(L, "manifest_map");
    lua_gettable(L, 2);
    lua_pushstring(L, svc_id);
    lua_newtable(L);
    lua_settable(L, 3);

    return 0;
}

// Lua: storm.n.svcd_add_attribute ( svc_id, attr_id, write_fn )
// Add a new attribute to a service in the service daemon
static void svcd_add_attribute( lua_State *L ) {

    //Get param 1 from top of stack
    char * svc_id = (char *) luaL_checkstring(L, 1);

    //Get param 2 from top of stack
    char * attr_id = (char *) luaL_checkstring(L, 2);

    //Get write_fn reference and pop it off
    int write_fn_ref = luaL_ref(L, LUA_REGISTRYINDEX);

    lua_getglobal(L, "SVCD"); //Index 3

    lua_pushstring(L, "blsmap"); //Index 4
    lua_gettable(L, 3);

    lua_pushstring(L, "blamap"); //Index 5
    lua_gettable(L, 3);
    lua_pushstring(L, svc_id); //Index 6
    lua_gettable(L, 5);
    lua_pushstring(L, attr_id); //Index 7 - key

    lua_pushlightfunction(L, libstorm_bl_addcharacteristic); //Index 8
    lua_pushstring(L, svc_id);
    lua_gettable(L, 4);
    lua_pushstring(L, attr_id);
    lua_rawgeti(L, LUA_REGISTRYINDEX, write_fn_ref);
    lua_call(L, 3, 1); //Returns at Index 8 - value

    lua_settable(L, 6); //Remove index 7, 8

    lua_pushstring(L, "manifest"); //Index 7
    lua_gettable(L, 3);
    lua_pushstring(L, svc_id); //Index 8
    lua_gettable(L, 7);
    int n = luaL_getn(L, 8);
    lua_pushstring(L, attr_id); //Index 9
    lua_rawseti(L, 8, n+1); //Index back to 8

    lua_pushstring(L, "manifest_map"); // Index 9
    lua_gettable(L, 3);
    lua_pushstring(L, svc_id); //Index 10
    lua_gettable(L, 9);
    lua_pushstring(L, attr_id); //Index 11
    lua_rawgeti(L, LUA_REGISTRYINDEX, write_fn_ref); //Index 12
    lua_settable(L, 10); //Index back to 10

    luaL_unref(L, LUA_REGISTRYINDEX, write_fn_ref);

    return 0;
}