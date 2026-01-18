// usm_ffi.h
// C header for USM Core FFI bindings
// Used as Swift bridging header

#ifndef USM_FFI_H
#define USM_FFI_H

#include <stdint.h>
#include <stddef.h>

// Opaque handle to USM Core instance
typedef struct UsmHandle UsmHandle;

// C-compatible service info
typedef struct {
    char *id;
    char *template_id;
    char *display_name;
    uint16_t port;
    int32_t status;      // 0=stopped, 1=running, 2=error, 3=starting, 4=stopping, 5=unknown
    double cpu_percent;
    uint64_t memory_mb;
} CServiceInfo;

// Array of service info
typedef struct {
    CServiceInfo *data;
    size_t len;
    size_t capacity;
} CServiceArray;

// Status codes
#define USM_STATUS_STOPPED  0
#define USM_STATUS_RUNNING  1
#define USM_STATUS_ERROR    2
#define USM_STATUS_STARTING 3
#define USM_STATUS_STOPPING 4
#define USM_STATUS_UNKNOWN  5

// Lifecycle functions
UsmHandle* usm_create(const char* config_path);
void usm_destroy(UsmHandle* handle);

// Service query functions
CServiceArray* usm_get_services(const UsmHandle* handle);
void usm_free_services(CServiceArray* array);

// Service control functions (return 0 on success, -1 on error)
int32_t usm_start_service(UsmHandle* handle, const char* instance_id);
int32_t usm_stop_service(UsmHandle* handle, const char* instance_id);
int32_t usm_restart_service(UsmHandle* handle, const char* instance_id);

// Utility functions
uint16_t usm_get_server_port(void);
const char* usm_version(void);

#endif // USM_FFI_H
