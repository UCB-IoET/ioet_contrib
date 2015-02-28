//This file is included into native.c


#define SVCD_SYMBOLS \
    { LSTRKEY( "svcd_init"), LFUNCVAL ( svcd_init ) },\ 
    { LSTRKEY( "svcd_write"), LFUNCVAL ( svcd_write )},


//If this file is defining only specific functions, or if it
//is defining the whole thing
#define SVCD_PUREC 0

// This is the metatable for the SVCD table. It will allow use to put some constants
// and symbols into ROM. We could of course put everything into ROM but that would
// prevent consumers from overriding the contents of the table for things like
// advert_received, which you may want to hook into
#define MIN_OPT_LEVEL 2
#include "lrodefs.h"

static const LUA_REG_TYPE svcd_meta_map[] =
{
    { LSTRKEY( "__index" ), LROVAL ( svcd_meta_map ) },
    { LSTRKEY( "OK" ), LNUMVAL ( 1 ) },
    { LSTRKEY( "TIMEOUT" ), LNUMVAL ( 2 ) },

    { LNILKEY, LNILVAL }
};


//////////////////////////////////////////////////////////////////////////////
// SVCD.init() implementation
// Maintainer: Michael Andersen <michael@steelcode.com>
/////////////////////////////////////////////////////////////
static int svcd_write( lua_State* L );

// The anonymous func in init that allows for dynamic binding of advert_received
static int svcd_init_adv_received( lua_State *L )
{
    int numargs = lua_gettop(L); // 3
    lua_getglobal(L, "SVCD");
    lua_pushstring(L, "advert_received");
    //Get the advert_received function from the table
    lua_gettable(L, -2); // resolved the string to the function which was a key in SVCD
    //Move it to before the arguments
    lua_insert(L, 1);
    //Pop off the SVCD table
    lua_settop(L, numargs + 1);
    //Note that we now call this function from C, so it cannot use any cord await
    //functions. If it needs to do that sort of thing, it can spawn a new cord to do so
    lua_call(L, numargs, 0);
    return 0;
}

// Lua: storm.n.svcd_init ( id, onready )
// Initialises the SVCD module, in global scope
static int svcd_init( lua_State *L )
{
    printf("INIT SVCD\n");
    if (lua_gettop(L) != 2) return luaL_error(L, "Expected (id, onready)");
#if SVCD_PUREC
//If we are going for a pure C implementation, then this would create the global
//SVCD table, otherwise it is created by the Lua code
        //Create the SVCD global table
        lua_createtable(L, 0, 8);
        //Set the metatable
        lua_pushrotable(L, (void*)svcd_meta_map);
        lua_setmetatable(L, 3);
        //Create the empty tables
        lua_pushstring(L, "manifest_map");
        lua_newtable(L);
        lua_settable(L, 3);
        lua_pushstring(L, "blsmap");
        lua_newtable(L);
        lua_settable(L, 3);
        lua_pushstring(L, "blamap");
        lua_newtable(L);
        lua_settable(L, 3);
        lua_pushstring(L, "oursubs");
        lua_newtable(L);
        lua_settable(L, 3);
        lua_pushstring(L, "subscribers");
        lua_newtable(L);
        lua_settable(L, 3);
        lua_pushstring(L, "handlers");
        lua_newtable(L);
        lua_settable(L, 3);
        lua_pushstring(L, "ivkid");
        lua_pushnumber(L, 0);
        lua_settable(L, 3);
        //Duplicate the TOS so the table is still there after
        //setglobal
        lua_pushvalue(L, -1);
        lua_setglobal(L, "SVCD");
#else
    //Load the SVCD table that Lua created
    //This will be index 3
    lua_getglobal(L, "SVCD");
    printf("Put table at %d\n", lua_gettop(L));
#endif
    //Now begins the part that corresponds with the lua init function

    //SVCD.write
    lua_pushstring(L, "write");
    lua_pushlightfunction(L, svcd_write);
    lua_settable(L, 3); // Store it in the table

    //SVCD.asock
    lua_pushstring(L, "asock");
    lua_pushlightfunction(L, libstorm_net_udpsocket);
    lua_pushnumber(L, 2525);
    lua_pushlightfunction(L, svcd_init_adv_received);
    lua_call(L, 2, 1);
    lua_settable(L, 3); //Store it in the table

    //SVCD.ssock
    lua_pushstring(L, "ssock");
    lua_pushlightfunction(L, libstorm_net_udpsocket);
    lua_pushnumber(L, 2526);
    lua_pushstring(L, "wdispatch");
    lua_gettable(L, 3);
    lua_call(L, 2, 1);
    lua_settable(L, 3); //Store

    //SVCD.nsock
    lua_pushstring(L, "nsock");
    lua_pushlightfunction(L, libstorm_net_udpsocket);
    lua_pushnumber(L, 2527);
    lua_pushstring(L, "ndispatch");
    lua_gettable(L, 3);
    lua_call(L, 2, 1);
    lua_settable(L, 3); //Store

    //SVCD.wcsock
    lua_pushstring(L, "wcsock");
    lua_pushlightfunction(L, libstorm_net_udpsocket);
    lua_pushnumber(L, 2528);
    lua_pushstring(L, "wcdispatch");
    lua_gettable(L, 3);
    lua_call(L, 2, 1);
    lua_settable(L, 3); //Store

    //SVCD.ncsock
    lua_pushstring(L, "ncsock");
    lua_pushlightfunction(L, libstorm_net_udpsocket);
    lua_pushnumber(L, 2529);
    lua_pushstring(L, "ncdispatch");
    lua_gettable(L, 3);
    lua_call(L, 2, 1);
    lua_settable(L, 3); //Store

    //SVCD.subsock
    lua_pushstring(L, "subsock");
    lua_pushlightfunction(L, libstorm_net_udpsocket);
    lua_pushnumber(L, 2530);
    lua_pushstring(L, "subdispatch");
    lua_gettable(L, 3);
    lua_call(L, 2, 1);
    lua_settable(L, 3); //Store

    //manifest table
    lua_pushstring(L, "manifest");
    lua_newtable(L);
    lua_pushstring(L, "id");
    lua_pushvalue(L ,1);
    lua_settable(L, -3);
    lua_settable(L, 3);

     //If id ~= nil
    if (!lua_isnil(L, 1)) {
        lua_pushlightfunction(L, libstorm_os_invoke_periodically);
        lua_pushnumber(L, 3*SECOND_TICKS);


        lua_pushlightfunction(L, libstorm_net_sendto);
        lua_pushstring(L, "asock");
        lua_gettable(L, 3);
        //Pack SVCD.manifest
        lua_pushlightfunction(L, libmsgpack_mp_pack);
        lua_pushstring(L, "manifest");
        lua_gettable(L, 3);
        lua_call(L, 1, 1);
        //Address
        lua_pushstring(L, "ff02::1");
        lua_pushnumber(L, 2525);
        cord_dump_stack(L);
        lua_call(L, 6, 0);

        //Enable the bluetooth
        lua_pushlightfunction(L, libstorm_bl_enable);
        lua_pushvalue(L, 1);
        lua_pushstring(L, "cchanged");
        lua_gettable(L, 3);
        lua_pushvalue(L, 2);
        lua_call(L, 3, 0);
    }

    return 0;
}

//////////////////////////////////////////////////////////////////////////////
// SVCD.write((string targetip, number svcid, number attrid, lightfunction payload, 
//                        number timeout_ms, lightfunction on_done)) 
// Authors: Aparna Dhinakaran, David Ho, Romi Phadte, Cesar Torres
/////////////////////////////////////////////////////////////


void resolve_table(lua_State *L, char* key){
    // push the global table, resolve it and then pop it off the stack
    lua_getglobal(L, "SVCD");
    lua_pushstring(L, key);
    lua_gettable(L, -2);
    lua_insert(L, -2);
    lua_settop(L, -2);
}

static int svcd_write_invoke_later(lua_State *L);
static int svcd_callback_handler(lua_State *L);
static int anon_function(lua_State *L);

static int svcd_callback_handler(lua_State *L){
    int ivkd = (int) lua_tonumber(L, lua_upvalueindex(1));
    printf("making callback function using ivkd = %i \n", ivkd);

    resolve_table(L, "TIMEOUT");
    int timeout = (int) lua_tonumber(L, -1);

    resolve_table(L, "handlers"); // 7
    lua_pushnumber(L, ivkd);
    lua_gettable(L, -2);

    int isnil = (int) lua_toboolean(L, -1);
    if(isnil != 0){
        lua_pushnumber(L, timeout);
        lua_call(L, 1, 0);

        resolve_table(L, "handlers"); // 7
        lua_pushnumber(L, ivkd);
        lua_pushnil(L);
        lua_settable(L, -3);
    }
    return 0;
}
static int anon_function(lua_State *L){
    int ivkd = (int)lua_tonumber(L, 1);
    printf("making anon function using ivkd = %i \n", ivkd);

    lua_pushnumber(L, ivkd);
    lua_pushcclosure(L, &svcd_callback_handler, 0);
    return 1;
}

// write 
static int svcd_write_invoke_later(lua_State *L){
    int ivkd = (int)lua_tonumber(L, 1);
    int timeout_ms = (int)lua_tonumber(L, 2);
    lua_pushlightfunction(L, libstorm_os_invoke_later);
    lua_pushnumber(L, timeout_ms * MILLISECOND_TICKS);
    
    printf("making custom anon funtion\n");
    // lua_pushlightfunction(L, anon_function);
    lua_getglobal(L, "anon_function");
        lua_pushnumber(L, ivkd);
        lua_call(L, 0, 1);
    printf("made custom anon funtion\n");

    lua_call(L, 2, 0);
    return 0;
}

static int svcd_write( lua_State *L )
{   
    // REGISTER CLUA FUNCTIONS IN GLOBAL SPACE
    // lua_pushcfunction(L, svcd_write_invoke_later);
    // lua_setglobal(L, "svcd_write_invoke_later");
    // lua_pushcfunction(L, anon_function);
    // lua_setglobal(L, "anon_function");
    // lua_pushcfunction(L, svcd_callback_handler);
    // lua_setglobal(L, "svcd_callback_handler");
    // END REGISTER

    printf("Sexy write!\n");    
    int numargs = lua_gettop(L); // 6
  
    // GET ALL THE ARGS
    size_t g;
    const char* targetip = (char*) lua_tolstring(L, 1, &g);
    int svcid = (int)lua_tonumber(L, 2);
    int attrid = (int)lua_tonumber(L, 3);
    
    size_t l;
    const char* payload =  lua_tolstring(L, 4, &l);

    int timeout_ms = (int)lua_tonumber(L, 5);
    int* on_done = (int*) lua_tonumber(L, 6);
     /* PARAMS */
    printf("Params (%i) received ip:%s, svc: 0x%x, attr: 0x%x, payload:%s, ondone= 0x%x \n", numargs, targetip, svcid, attrid, payload, on_done);
    
    /* SET IVKID */
    resolve_table(L, "ikvid"); //7
    int ivkid = (int) lua_tonumber(L, -1);
   
    printf("Getting ikvid: %i\n", ivkid);
  
    ivkid =  ivkid + 1;
    if( ivkid > 65535 ) { 
        ivkid = 0;
    }

    lua_settop(L, numargs);

    printf("Updating ikvid to %i\n", ivkid);
    // setting ivkid
    lua_getglobal(L, "SVCD");
    lua_pushnumber(L, ivkid);
    lua_setfield(L, -2, "ikvid");
    lua_settop(L, numargs);
    /* END SET IVKID*/
 
    /* SET HANDLER */
    printf("Setting handler\n");
    resolve_table(L, "handlers"); // 7
    printf("Resolved handlers\n");

    lua_pushnumber(L, ivkid);
    printf("Resolved ikvid handler\n");
    lua_pushlightfunction(L, on_done);

    lua_settable(L, -3);
    /* END SET HANDLER */

    /* INVOKE LATER */
    printf("Setting up invoke later \n");
    
    /* CUSTOM WRITE INVOKE */
    // lua_getglobal(L, "scvd_write_invoke_later");
    // lua_pushnumber(L, ivkid);
    // lua_pushnumber(L, timeout_ms);
    // printf("Calling invoke later custom \n");
    // lua_call(L, 2, 0);
    /* END CUSTOM */

    
    /* LUA WRITE INVOKE */
    resolve_table(L, "write_invoke_later"); // 9
     //function write invoke later 
        lua_pushnumber(L, ivkid);  // 10
        lua_pushnumber(L, timeout_ms);
        printf("Calling invoke later \n");
        lua_call(L, 2, 0);
    /* END LUA WRITE INVOKE */


    /* SEND TO */
    printf("Setting up sendto \n");
    lua_pushlightfunction(L, libstorm_net_sendto); 
    // resolve_table(L, "print_sendto"); 
        resolve_table(L, "wcsock");
        /* BEGIN MESSAGE PACK */
        printf("Setting up msg_pack array \n");
        lua_pushlightfunction(L, libmsgpack_mp_pack);
            lua_newtable(L);
            //svcid
            lua_pushnumber(L, 1);
            lua_pushnumber(L, svcid);
            lua_settable(L, -3);
            printf("Appending svcid 0x%x\n", svcid);
            //attrid
            lua_pushnumber(L, 2);
            lua_pushnumber(L, attrid);
            lua_settable(L, -3);
            printf("Appending attrid 0x%x\n", attrid);

            // ivkid
            lua_pushnumber(L, 3);
            lua_pushnumber(L, ivkid); //14
            lua_settable(L, -3);
            printf("Appending ivkid 0x%x\n", ivkid);

            //payload
            lua_pushnumber(L, 4);
            lua_pushlstring(L, payload, l);
            lua_settable(L, -3);
            printf("Appending payload %s\n", payload);

        printf("Calling msg_pack \n");
        lua_call(L, 1, 1);

        /* END OF MSG PACK FUNCTION */

        // targetip    
        lua_pushlstring(L, targetip, g);
        //2526
        lua_pushnumber(L, 2526);

    printf("Calling sendto\n");
    lua_call(L, 4, 0);
    /* END SEND_TO */

    return 0; //return # of arguments
}



