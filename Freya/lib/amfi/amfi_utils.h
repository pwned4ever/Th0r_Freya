//Used to be electra


#include <Foundation/Foundation.h>


bool is_amfi_cache(NSString *path);
NSString *cdhashFor(NSString *file);
int injectTrustCache(NSArray <NSString*> *files, uint64_t trust_chain, int (*pmap_load_trust_cache)(uint64_t, size_t));
