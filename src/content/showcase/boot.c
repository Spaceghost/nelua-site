  unsigned long flags = ((MS_NODEV | MS_NOEXEC) | MS_NOSUID);
  earlyboot_mount_one(((nlstring){(uint8_t*)"proc", 4}), ((nlstring){(uint8_t*)"/proc", 5}), ((nlstring){(uint8_t*)"proc", 4}), flags);
  earlyboot_mount_one(((nlstring){(uint8_t*)"sysfs", 5}), ((nlstring){(uint8_t*)"/sys", 4}), ((nlstring){(uint8_t*)"sysfs", 5}), flags);
  setenv((char*)"PATH", (char*)"/bin:/sbin", 1);
  earlyboot_report(((nlstring){(uint8_t*)"theseus: starting console shell", 31}));
