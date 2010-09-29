
struct devsw {
  int (*read)(struct inode*, char*, int);
  int (*write)(struct inode*, char*, int);
};

extern struct devsw devsw[];

// only one device for now ... ??? TODO and when read file ??
#define CONSOLE 1
