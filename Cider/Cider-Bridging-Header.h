//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//


//#include "../DiscordRPCAgent/Generated/SwiftBridgeCore.h"
#include "../NativeUtils/Generated/SwiftBridgeCore.h"

#include "../DiscordRPCAgent/Generated/discord-rpc-agent/discord-rpc-agent.h"
#include "../NativeUtils/Generated/native-utils/native-utils.h"

#ifdef __cplusplus
#define extern "C" {
#endif

int initCXXNativeUtils();
int initLogViewer();
void addLogEntry(const char* time, const char* level, const char* message);
void showLogViewer();
void terminateCXXNativeUtils();

#ifdef __cplusplus
#define }
#endif
