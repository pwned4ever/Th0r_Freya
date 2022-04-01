int vnode_lookup(const char *path, int flags, uint64_t *vnode, uint64_t vfs_context);
uint64_t _vfs_context(void);
int _vnode_put(uint64_t vnode);
uint64_t vnodeForPath(const char *path);
int64_t vnodeForSnapshot(int fd, char *name);
uint64_t zm_fix_addr(uint64_t addr);
