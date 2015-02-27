/*
 * GOAL
 * ----------------------------------------------------------------------
 * local ivkid = SVCD.ivkid
 *     SVCD.ivkid = SVCD.ivkid + 1
 *     if SVCD.ivkid > 65535 then
 *         SVCD.ivkid = 0
 *     end
 *     SVCD.handlers[ivkid] = on_done
 *     storm.os.invokeLater(timeout_ms*storm.os.MILLISECOND, function()
 *         if SVCD.handlers[ivkid] ~= nil then
 *             SVCD.handlers[ivkid](SVCD.TIMEOUT)
 *             SVCD.handlers[ivkid] = nil
 *         end
 *     end)
 *     storm.net.sendto(SVCD.wcsock, storm.mp.pack({svcid, attrid, ivkid, payload}), targetip, 2526)
 * Compile: gcc svcd_write.c -o write
 * Run: ./write
 */
#include "svcd_write.h"

void svcd_write(char* targetip, uint8_t svcid, uint8_t attrid, 
    char* payload, uint8_t timeout_ms, char* on_done){
    printf("%s, %s\n", targetip, payload);
   
}

int main(int argc, char const *argv[])
{
    // TEST SUITE
    printf( "Test 1: Param Echo \nExpected: ff02::1, Hello World\n" );
    printf( "Observed: " );
    svcd_write("ff02::1", 2, 3, "Hello World\0", 200, NULL);
    printf( "\n" );
    return 0;
}