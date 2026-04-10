 /* 
 * meminfo - Time/Memory monitor for FastCR competitive programming tool.
 * Usage: meminfo <timeout_ms> <memory_limit_MB> <cmd> [args...]
 * Output to stderr (parsed by cr.sh):
 * STATUS:OK|TLE|RTE
 * TIME:<ms> (user+sys)
 * MEM:<kb> (max RSS)
 * EXIT:<code> or SIGNAL:<sig>
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>
#include <sys/resource.h>
#include <sys/time.h>
#include <signal.h>
#include <string.h>
#include <fcntl.h>
#include <limits.h>
#include <errno.h>

static volatile pid_t child_pid = 0;

void handler(int sig) {
    (void)sig;
    if (child_pid > 0) {
        kill(child_pid, SIGKILL);
    }
}

int main(int argc, char *argv[]) {
    if (argc < 4) {
        fprintf(stderr, "Usage: meminfo <timeout_ms> <memory_limit_MB> <cmd> [args...]\n");
        return 1;
    }

    long timeout_ms = strtol(argv[1], NULL, 10);
    if (timeout_ms <= 0 || timeout_ms > 3600000) {  // Reasonable limits: 1hr max
        fprintf(stderr, "Invalid timeout: %s\n", argv[1]);
        return 1;
    }

    long mem_limit_mb = strtol(argv[2], NULL, 10);
    if (mem_limit_mb <= 0 || mem_limit_mb > 4096) {  // 4GB max
        fprintf(stderr, "Invalid memory limit: %s\n", argv[2]);
        return 1;
    }

    struct itimerval timer = {0};
    timer.it_value.tv_sec = timeout_ms / 1000;
    timer.it_value.tv_usec = (timeout_ms % 1000) * 1000;

    struct rlimit mem_lim = {0};
    mem_lim.rlim_cur = mem_limit_mb * 1024L * 1024L;
    mem_lim.rlim_max = mem_lim.rlim_cur;

    struct sigaction sa = {0};
    sa.sa_handler = handler;
    sigemptyset(&sa.sa_mask);
    sa.sa_flags = 0;
    sigaction(SIGALRM, &sa, NULL);
    sigaction(SIGINT, &sa, NULL);
    sigaction(SIGTERM, &sa, NULL);

    pid_t pid = fork();
    if (pid < 0) {
        perror("fork");
        return 1;
    } else if (pid == 0) {
        // Child: set limits and exec
        setrlimit(RLIMIT_AS, &mem_lim);
        setpgid(0, 0);  // New process group for killpg if needed
        execvp(argv[3], &argv[3]);
        perror("execvp");
        _exit(127);
    }

    // Parent
    child_pid = pid;
    if (setitimer(ITIMER_REAL, &timer, NULL) < 0) {
        perror("setitimer");
        kill(pid, SIGTERM);
        waitpid(pid, NULL, 0);
        return 1;
    }

    int status;
    struct rusage usage;
    wait4(pid, &status, 0, &usage);

    setitimer(ITIMER_REAL, NULL, NULL);
    child_pid = 0;

    // Determine status
    const char* status_str;
    if (WIFSIGNALED(status) && (WTERMSIG(status) == SIGKILL || WTERMSIG(status) == SIGALRM)) {
        status_str = "TLE";
    } else if (WIFSIGNALED(status)) {
        fprintf(stderr, "STATUS:RTE\nSIGNAL:%d\n", WTERMSIG(status));
        status_str = NULL;  // Already printed
    } else if (WIFEXITED(status)) {
        fprintf(stderr, "STATUS:OK\nEXIT:%d\n", WEXITSTATUS(status));
        status_str = NULL;  // Already printed
    } else {
        status_str = "RTE";
    }

    if (status_str) {
        fprintf(stderr, "STATUS:%s\n", status_str);
    }

    // Usage stats
    long time_ms = (usage.ru_utime.tv_sec * 1000L + usage.ru_utime.tv_usec / 1000L) +
                   (usage.ru_stime.tv_sec * 1000L + usage.ru_stime.tv_usec / 1000L);
    long mem_kb = usage.ru_maxrss;

    fprintf(stderr, "TIME:%ld\nMEM:%ld\n", time_ms, mem_kb);

    return 0;
}

