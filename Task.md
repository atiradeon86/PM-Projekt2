# Project task
## Create a PowerShell script that performs the following tasks, including precondition checks, error handling, and logging.

The script should be well-commented and structured for easy navigation, even by someone who is seeing it for the first time.

1. Include a header in the script that provides information such as:

* Script name
* Version
* Application or service it is related to
* Author and creation date
* Last modified by and date
* Purpose of the script

2. Define variables at the beginning of the script or in a configuration file.

3. Log output to both the screen and a file during script execution. If there isn't a built-in logging feature, create a custom function for this purpose.
4. At the beginning, display a summary:
* Name of the script that started
* Timestamp of when the script started
* Who initiated the script
* Server name where the script is running
* Origin of the script's execution (dynamically read, as it's unknown who will initiate it)
* Location of the log file
5. Prompt for a password during execution, and emphasize the need for this password at the beginning.
6. Verify that all necessary prerequisites are met for successful execution:
* Check if it was launched with local admin privileges; if not, exit and display an error.
* Check if the required .NET version is installed.
* Determine available drives and select the best one.
* If any of the prerequisites are not met, exit and provide information on what is missing on the screen.
7. Grant permissions to a service account to write to the Application Event log.
8. Create a custom event source in the Application log.
9. Create a directory structure on the previously selected drive.
10. Set the necessary NTFS permissions on this directory.
11. Enable sharing on the directory with the required permissions.
12. Copy program files from a central server to the specified subdirectory.
13. Correct the server name in the program's configuration file.
14. Create a Scheduled Task that launches the previous program based on two scheduling criteria:
* Time-based scheduling
* When a specific Application event log entry is created.
* Request the required password. Ensure that the password is not displayed on the screen during input.
15. Create another directory structure on the previously selected drive.
16. Set the necessary NTFS permissions on this directory.
17. Enable sharing on the directory with the required permissions.
18. Display the completion time of the script.
19. At the end, provide information on where to find the log file.

Note: The support for creating scheduled tasks in PowerShell may have evolved since the script was created. 
If there is now a native solution for event-based scheduling, it should be utilized instead of manually creating scheduled tasks as described in the script's comments.