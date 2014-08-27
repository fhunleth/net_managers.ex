#define _GNU_SOURCE
#include <errno.h>
#include <err.h>
#include <poll.h>
#include <signal.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <unistd.h>

#define UDHCPC_PATH "/sbin/udhcpc"
//#define UDHCPC_PATH "/usr/bin/whoami"

static pid_t child_pid;
static int exitpipefd[2];

static void child(int argc, char *argv[])
{
    // Close the file descriptors that the child isn't supposed to use.
    close(exitpipefd[0]);
    close(exitpipefd[1]);
    close(STDIN_FILENO);

    // Launch the child with arguments
    char *udhcpc_argv[argc + 1];
    udhcpc_argv[0] = strdup(UDHCPC_PATH);
    memcpy(&udhcpc_argv[1], &argv[1], (argc - 1) * sizeof(char *));
    udhcpc_argv[argc] = NULL;

    execv(udhcpc_argv[0], udhcpc_argv);
    err(EXIT_FAILURE, "execv");
}

static void process_erlang_request()
{
    char buffer[128];

    ssize_t amount = read(STDIN_FILENO, buffer, sizeof(buffer));
    if (amount <= 0) {
        // Error or Erlang closed the port -> we're done.
        kill(child_pid, SIGKILL);
        exit(EXIT_SUCCESS);
    }

    ssize_t i;
    for (i = 0; i < amount; i++) {
        // Each command is a byte.
        switch (buffer[i]) {
        case 1:
            kill(child_pid, SIGUSR1);
            break;
        case 2:
            kill(child_pid, SIGUSR2);
            break;
        default:
            kill(child_pid, SIGKILL);
            errx(EXIT_FAILURE, "unexpected command: %d", buffer[i]);
        }
    }
}

static void parent()
{
    for (;;) {
        struct pollfd fdset[2];

        fdset[0].fd = STDIN_FILENO;
        fdset[0].events = POLLIN;
        fdset[0].revents = 0;

        fdset[1].fd = exitpipefd[0];
        fdset[1].events = POLLIN;
        fdset[1].revents = 0;

        int rc = poll(fdset, 2, -1);
        if (rc < 0) {
            // Ignore EINTR
            if (errno == EINTR)
                continue;

            kill(child_pid, SIGKILL);
            err(EXIT_FAILURE, "poll failed");
        }

        if (fdset[0].revents & (POLLIN | POLLHUP))
            process_erlang_request();

        if (fdset[1].revents & (POLLIN | POLLHUP)) {
            // When the child exits, we exit.
            return;
        }
    }
}

static void signal_handler(int sig)
{
    if (sig == SIGCHLD) {
        // On SIGCHLD, write a byte to the pipe to wake up poll
        char buffer = 0;
        if (write(exitpipefd[1], &buffer, 1) < 0)
            err(EXIT_FAILURE, "write");
    } else {
        // Pass the signal onto the child
        kill(child_pid, sig);
    }
}

static void force_identity()
{
    // udhcpc needs to run with a real identify (ruid) of root.
    // Just marking the udhcpc_wrapper binary as setuid root
    // isn't good enough since that just updates the effective
    // and saved uids. This takes it all the way.
    uid_t ruid, euid, suid;
    getresuid(&ruid, &euid, &suid);
    if (ruid != 0 && setresuid(euid, euid, euid) < 0)
        errx(EXIT_FAILURE, "Can't elevate to root permissions required by udhdpc");
}

int main(int argc, char *argv[])
{
    // Make sure the udhcpc has permission to run before going farther.
    force_identity();

    // Set up the pipe for notifying the parent's poll loop of SIGCHLD.
    if (pipe(exitpipefd) < 0)
        err(EXIT_FAILURE, "pipe");

    // Capture SIGCHLD and other signals relevant to udhcpc
    struct sigaction sigact;
    sigact.sa_handler = signal_handler;
    sigemptyset(&sigact.sa_mask);
    sigact.sa_flags = 0;
    sigaction(SIGCHLD, &sigact, NULL);
    sigaction(SIGINT, &sigact, NULL);

    // Fork
    child_pid = fork();
    if (child_pid < 0)
        err(EXIT_FAILURE, "fork");

    if (child_pid == 0)
        child(argc, argv);
    else
        parent();

    exit(EXIT_SUCCESS);
}

