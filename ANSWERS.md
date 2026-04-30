# Lab 10 - Analysis Questions

## 1. Security Risk: Why is a world-writable directory more dangerous than a world-writable file?

A world-writable directory is way more dangerous because it lets any user create, delete, or rename files inside it, not just change one file. So an attacker could drop a malicious script in there, like a backdoor or a fake version of a real program. If that directory is on the system PATH or being served by a web server, the malicious file could get executed automatically. With a world-writable file, the worst they can do is mess with that one file's contents. But with a directory, they can add brand new files and delete existing ones, which opens up a lot more attack possibilities.

## 2. Permission Bits: Explain `-perm -002` vs `-perm /111`

`-perm -002` means "all of these bits must be set." The 002 in octal is the others/world write bit. The dash in front tells find to match anything where at least that bit is on, no matter what other bits are set too. So it catches anything world-writable like 666, 777, etc.

`-perm /111` means "any of these bits can be set." The 111 covers the execute bit for owner, group, and others. The slash tells find to match if any one of those execute bits is turned on.

We use the dash (AND logic) for world-writable because we only care about one specific bit. We use the slash (OR logic) for executable because we want to flag a file if anyone at all can execute it.

## 3. Real-World Impact: 50 world-writable files on a production web server

If I found 50 world-writable files on a production server, here's what I would do right away:

- First, figure out which ones are the most sensitive. Config files with passwords, anything served on the web, and system files get top priority.
- Strip the world-writable permission on all of them using `chmod o-w` to stop the bleeding.
- Check if any of the files have already been tampered with by looking at timestamps with `stat` or comparing against version control.
- Go through access logs and system logs to see if anyone already exploited the bad permissions.
- Figure out how the permissions got set wrong in the first place, whether it was a bad deploy script, a wrong umask, or someone doing it manually, and fix the root cause.
- Set up automated scanning (like running this script on a cron job) so it doesn't happen again.

## 4. Process Substitution: Why `find ... | while read` fails for counting

When you use a pipe (`find ... | while read`), the while loop runs in a subshell. That's basically a separate child process with its own copy of all the variables. So when you increment `count` inside that subshell, the change gets thrown away when the loop ends and you're back in the parent shell. Count stays at 0.

With process substitution (`done < <(find ...)`), the while loop runs in the current shell, not a subshell. The `<(find ...)` part creates a temporary file descriptor that feeds into the loop, but the actual loop code runs in the main shell process. So when you increment count, it sticks around after the loop is done and you get the right number.

## 5. Automation: Schedule the script to run daily at 2 AM

You can use a cron job to schedule it and send the output by email:

```bash
# Edit the crontab
crontab -e

# Add this line:
0 2 * * * /home/student/cus1163-lab10/security_scanner.sh 2>&1 | mail -s "Daily Security Scan Report" security-team@company.com
```

The cron expression `0 2 * * *` breaks down to minute 0, hour 2, every day of the month, every month, every day of the week. The `2>&1` part redirects error output to standard output so you catch everything. The `mail` command sends all of that to the security team's email. You would need a mail transfer agent like postfix or sendmail set up on the server for this to actually send.
